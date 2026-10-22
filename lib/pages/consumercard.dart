import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';
import 'package:meter_reader_flutter/models/consumercard_model.dart';
import 'package:meter_reader_flutter/helpers/calculatebill_helper.dart';
import 'package:meter_reader_flutter/helpers/notes_helper.dart';
import 'package:meter_reader_flutter/models/consumer_note_model.dart';
import 'package:meter_reader_flutter/models/prefs_model.dart';
import 'package:intl/intl.dart';
import 'package:meter_reader_flutter/helpers/blueprinter_helper.dart';
import 'package:meter_reader_flutter/helpers/appsettings_helper.dart';
import 'package:provider/provider.dart';

import 'consumercard/consumer_info_card.dart';
import 'consumercard/readers_field.dart';
import 'consumercard/particulars_container.dart';
import 'consumercard/bottom_buttons.dart';

//Card after postmeter list
class Consumercard extends StatefulWidget {
  const Consumercard({super.key});

  @override
  State<Consumercard> createState() => _ConsumercardState();
}

class _ConsumercardState extends State<Consumercard> {
  ConsumercardModel? _currentCard;

  int? _cardId;
  int? _newReading;
  Future<ConsumercardModel?>? _cardFuture;
  int? _rateType;
  bool _cardInitialized = false;

  double? _usage;
  double? _calculatedBill;
  double? _beforeDatecalculation;
  double? _afterDatecalculation;
  double? _calculatedSCDisc;
  String scDiscLimitWarning = 'Limit Usage for Senior Citezen Discount';
  String? _currentReadingDate; //holds card.cardcurrentReadingDate
  double? _ftax;
  double? _penaltyValue;
  double? _flatbill;

  bool _billUpdated = false;
  bool _isSaving = false;
  bool _ftaxActivate = false;
  bool _penaltyActivate = false;
  bool _noteActivate = false;
  bool _billingFeaturesLoaded = false;
  //String? _formattedDate =
  //    DateFormat('MM-dd-yyyy').format(DateTime.now().add(Duration(days: 15)));

  // Retrieve the card ID from the route arguments.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cardFuture != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _cardId = args;
      _cardFuture = getConsumercardByID(_cardId!);
    } else {
      // Optional: fallback if no valid argument is passed.
      Navigator.pushNamed(context, '/');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFlatbill();
    _loadBillingFeatures();
  }

  Future<void> _loadBillingFeatures() async {
    final settings = AppSettingsHelper();
    final ftaxEnabled = await settings.isEnabled('feature_ftax');
    final penaltyEnabled = await settings.isEnabled('feature_penalty');
    if (!mounted) return;
    setState(() {
      _ftaxActivate = ftaxEnabled;
      _penaltyActivate = penaltyEnabled;
      _billingFeaturesLoaded = true;
    });
  }

  // Future<void> _checkforFtax() {
  //   if (_currentCard != null) {
  //     setState(() {
  //       _ftaxActivate =
  //           _currentCard!.prefsFtax != null && _currentCard!.prefsFtax != 0;
  //     });
  //   }
  // }

  Future<void> _loadFlatbill() async {
    final value = await CalculatebillHelper.getFlatbill();
    setState(() => _flatbill = value);
  }

  // Check for negative usage and show confirmation dialog
  Future<bool> _checkNegativeUsage() async {
    if (_usage != null && _usage! < 0) {
      return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  'WARNING!',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
                ),
                content: const Text(
                  'The Usage is NEGATIVE, are you sure you want to continue?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                actions: <Widget>[
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red),
                    ),
                    child: const Text(
                      'No',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.green),
                    ),
                    child: Text(
                      'Yes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ) ??
          false; // Return false if dialog is dismissed
    }
    return true; // Continue if usage is not negative
  }

  // Handles the Print Button click event.
  Future<void> handlePrintButton() async {
    // Check for negative usage first
    bool shouldContinue = await _checkNegativeUsage();
    if (!shouldContinue || !mounted) return;

    final bluetoothHelper = context.read<BluePrinterHelper>();
    if (bluetoothHelper.connected == true &&
        await bluetoothHelper.bluetooth.isConnected == true) {
      if (_calculatedBill == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Current Reading yet.')),
        );
      } else {
        int billStatePrinted = 2;
        await updateMasterRecord(billStatePrinted, 0);
        try {
          if (_currentCard != null) {
            await _printReceipt(_currentCard!);
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bill Printing')),
          );
          Navigator.pop(context, true);
        } catch (e) {
          bluetoothHelper.connected = false;
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Printer disconnected during print!')),
          );
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected!')),
      );
    }
  }

//Handles the Save Button click event.
  Future<void> handleSaveButton() async {
    // Check if there is input (adjust the condition as needed for your logic)
    if (_newReading == null && _usage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please input a reading before saving.')),
      );
      return;
    }

    // Check for negative usage first
    bool shouldContinue = await _checkNegativeUsage();
    if (!shouldContinue || !mounted) return;

    int billStateSaved = 1;
    await updateMasterRecord(billStateSaved, 0);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> handlePrintFlat() async {
    final bluetoothHelper = context.read<BluePrinterHelper>();
    if (bluetoothHelper.connected == true &&
        await bluetoothHelper.bluetooth.isConnected == true) {
      int billStatePrinted = 2;
      await updateMasterRecord(billStatePrinted, 1);
      try {
        if (_currentCard != null) {
          await _printReceiptFlat(_currentCard!);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill Printing')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        bluetoothHelper.connected = false;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer disconnected during print!')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected!')),
      );
    }
  }

  Future<void> updateMasterRecord(int billStatind, int ratetype) async {
    //setState(() => _isSaving = true);
    // Ensure _newReading is set to card.cardCurrreading if null or 0
    if (ratetype == 0) {
      if (_newReading == null) {
        if (_currentCard != null) {
          _newReading = _currentCard!.cardCurrreading;
        }
      }
      if (_cardId != null &&
          _calculatedBill != null &&
          _usage != null &&
          _newReading != null &&
          _calculatedSCDisc != null) {
        // Convert calculated bill to cents and then to int.

        double dbBill = _calculatedBill! * 100;
        double scDisc = _calculatedSCDisc! * 100;
        int pca = (_ftax! * 100).round();

        int finalSCdisc = scDisc.toInt();
        int calculateBillInt = dbBill.toInt();
        int usageInt = _usage!.toInt();
        int penalty = 0;

        int isPosted = 1;
        int billStatus =
            billStatind; //indicator just 1 if only saved, 2 if saved and printed
        int? isNewReading = _newReading;
        String dateUpdated =
            _currentReadingDate!; // Use the current date from the state
        Map<String, dynamic> updatedData = {
          'AMOUNT': calculateBillInt,
          'USAGE': usageInt,
          'POSTED': isPosted,
          'BILL_STAT': billStatus,
          'CREADING': isNewReading,
          'MCRDGDT': dateUpdated,
          'SCDISC': finalSCdisc,
          'PEN': penalty,
          'PCA': pca,
        };

        try {
          int count =
              await DatabaseHelper().updateMasterData(_cardId!, updatedData);
          if (!mounted) {
            //setState(() => _isSaving = false);
            return;
          }
          if (count > 0) {
            // Optionally fetch the updated record for debugging.
            //Map<String, dynamic>? updatedRecord =
            //  await DatabaseHelper().getMasterByID(_cardId!);
            //print("Updated record data: $updatedRecord");

            if (!mounted) {
              setState(() => _isSaving = false);
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Record updated successfully!')),
            );
            // setState(() {
            //   _cardFuture = getConsumercardByID(_cardId!);
            // });
            _currentCard = await getConsumercardByID(_cardId!);
            //Navigator.pushNamed(context, '/postmeterreading');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Update failed.')),
            );
          }
        } catch (e) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving the record: $e')),
          );
        }
      }
    } else if (ratetype == 1 && _cardId != null) {
      try {
        final count = await DatabaseHelper().updateMasterData(_cardId!, {
          'POSTED': 1,
          'BILL_STAT': billStatind,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                count > 0 ? 'Record updated successfully!' : 'Update failed.'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving the record: $e')),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _printReceipt(ConsumercardModel card) async {
    final bluetoothHelper = context.read<BluePrinterHelper>();
    final int usageValue = ((_usage ?? card.cardUsage ?? 0) as num).toInt();
    NumberFormat formatter = NumberFormat('#,##0.00');
    String formattedBill = formatter.format(_beforeDatecalculation ?? 0.0);
    final double ftaxValue = (_ftax ?? 0.0).toDouble();
    final double afterDue = (_afterDatecalculation ?? 0.0).toDouble();
    final double penaltyValue = (_penaltyValue ?? 0.0).toDouble();
    final double waterBill =
        ((_calculatedBill ?? card.cardCurrbill ?? 0.0) as num).toDouble();
    BillBreakdown breakdown;

    try {
      if (card.cardCodeRaw.trim().length >= 3) {
        breakdown = await CalculatebillHelper.calculateBillBreakdown(
          card.cardCodeRaw,
          usageValue,
        );
      } else {
        breakdown = BillBreakdown(
          total: waterBill,
          tiers: [
            BillTier(
              label: 'WATER BILL',
              amount: waterBill,
              units: 0,
              ratePerUnit: 0,
            )
          ],
        );
      }
    } catch (_) {
      breakdown = BillBreakdown(
        total: waterBill,
        tiers: [
          BillTier(
            label: 'WATER BILL',
            amount: waterBill,
            units: 0,
            ratePerUnit: 0,
          )
        ],
      );
    }

    final receiptMessages = await AppSettingsHelper().getReceiptMessages();
    final messageText1 = receiptMessages[0];
    final messageText2 = receiptMessages[1];
    final messageText3 = receiptMessages[2];

    await bluetoothHelper.printReceipt(
        _currentReadingDate.toString(),
        card.prefsDatedue.toString(),
        card.cardName,
        card.cardAddress,
        card.cardMeterno,
        card.cardMeterbrand,
        card.cardAccno,
        (_newReading ?? card.cardCurrreading)
            .toString(), // Use new reading if available
        card.cardPrevreading.toString(),
        usageValue,
        waterBill.toStringAsFixed(2),
        card.cardWmf.toStringAsFixed(2),
        card.cardArrears,
        formattedBill,
        card.prefsCutdate.toString(),
        card.cardprevReadingDate,
        card.prefsBilldate,
        card.cardAvusage.toString(),
        card.cardOthers.toStringAsFixed(2),
        card.cardRefNo,
        card.prefsReadername,
        card.cardwithSeniorDisc,
        card.cardOthers.toStringAsFixed(2),
        card.cardPreviousUsage,
        ftaxValue,
        _ftaxActivate,
        messageText1,
        messageText2,
        messageText3,
        afterDue,
        _penaltyActivate,
        penaltyValue,
        breakdown);
  }

  Future<void> _printReceiptFlat(ConsumercardModel card) async {
    final bluetoothHelper = context.read<BluePrinterHelper>();

    String waterbillString = (_flatbill ?? 0.0).toStringAsFixed(2);
    double flatTotaldue = (_flatbill ?? 0.0) + card.cardArrears;
    String messageText1 = '';
    String messageText2 = '';
    String messageText3 = '';

    await bluetoothHelper.printReceiptFlat(
        _currentReadingDate.toString(),
        card.prefsDatedue,
        card.cardName,
        card.cardAddress,
        card.cardAccno,
        waterbillString,
        card.cardArrears,
        flatTotaldue.toStringAsFixed(2),
        card.prefsBilldate,
        card.cardprevReadingDate,
        card.cardRefNo,
        messageText1,
        messageText2,
        messageText3);
  }

  String getCurrentReadingDate(ConsumercardModel card) {
    return card.cardcurrentReadingDate;
  }

  String getFormattedReadingDate(String cardcurrentReadingDate) {
    try {
      // Parse the original date string (assumed format: MM/dd/yyyy)
      DateTime date = DateFormat('MM/dd/yyyy').parse(cardcurrentReadingDate);
      // Format as yyyy-MM-dd
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      // If parsing fails, return the original string
      return cardcurrentReadingDate;
    }
  }

  /// Calls the billing helper and updates the _calculatedBill state.
  void _updateBill(ConsumercardModel card, double usage) async {
    try {
      // check if I have previous usage
      if (card.cardPreviousUsage >= 0) {
        //add the previous usage to the current usage
        usage += card.cardPreviousUsage.toDouble();
      }
      // card.cardCodeRaw is used as the CSSSZ code.
      double bill = await CalculatebillHelper.calculateBill(
          card.cardCodeRaw, usage.toInt());
      double scDisc;
      if (card.cardwithSeniorDisc == 1 && _usage! < 31) {
        scDisc = bill * 0.05;
      } else {
        scDisc = 0.00;
      }

      double fTaxValue = 0;
      if (_ftaxActivate) {
        fTaxValue = (bill - scDisc) * (card.prefsFtax / 100);
      }

      double wTaxValue = 0;
      if (card.cardWtaxExempt == 1){
        wTaxValue = bill * 0.02;
      }

      double penalty = 0;
      if (_penaltyActivate) {
        penalty = (card.prefsPenper / 100) + 1;
      }
      int penaltyOption = 1;
      double penaltyValue = 0;
      if (_penaltyActivate) {
        if (penaltyOption == 1) {
          penaltyValue = (bill - scDisc) * (card.prefsPenper / 100);
        }
      }
      double totalBeforeDue = 0.00;
      double totalAfterDue = 0.00;
      if (card.cardWtaxExempt == 0) {
        totalBeforeDue = ((bill - scDisc) + fTaxValue) +
            card.cardArrears +
            card.cardOthers +
            card.cardWmf;
        totalAfterDue = (((bill - scDisc)) * penalty) +
            fTaxValue +
            card.cardArrears +
            card.cardOthers +
            card.cardWmf;
      } else if (card.cardWtaxExempt == 1){
        totalBeforeDue = ((bill) + wTaxValue) +
            card.cardArrears +
            card.cardOthers +
            card.cardWmf;
        totalAfterDue = (((bill)) * penalty) +
            wTaxValue +
            card.cardArrears +
            card.cardOthers +
            card.cardWmf;
      }

      setState(() {
        _calculatedBill = bill;
        _beforeDatecalculation = totalBeforeDue;
        _afterDatecalculation = totalAfterDue;
        _calculatedSCDisc = scDisc;
        _ftax = fTaxValue;
        _penaltyValue = penaltyValue;
      });
    } catch (e) {
      print("Error calculating bill: $e");
      setState(() {
        _calculatedBill = null;
        _beforeDatecalculation = null;
        _afterDatecalculation = null;
        _calculatedSCDisc = null;
        _ftax = null;
        _penaltyValue = null;
      });
    }
  }

  //Builds the widget tree for the Consumercard page.
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: cardAppBar(context),
          body: FutureBuilder<ConsumercardModel?>(
            future: _cardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text("No data found."));
              } else {
                final card = snapshot.data!;
                if (!_cardInitialized) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _currentCard?.cardId != card.cardId) {
                      setState(() {
                        _currentCard = card;
                        _rateType = card.cardRateType;
                        String formattedDate = getFormattedReadingDate(
                            card.cardcurrentReadingDate);
                        String onlyTime =
                            DateFormat('HH:mm:ss').format(DateTime.now());
                        String datePart = formattedDate.split(' ').first;
                        _currentReadingDate = '$datePart $onlyTime';
                      });
                    }
                  });
                  if (_billingFeaturesLoaded &&
                      !_billUpdated &&
                      card.cardUsage != 0) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _updateBill(card, card.cardUsage);
                      setState(() {
                        _usage = card.cardUsage;
                        _billUpdated = true;
                      });
                    });
                  }
                  _cardInitialized = true;
                }
                return Column(
                  children: [
                    Center(child: ConsumerInfoCard(card: card)),
                    const SizedBox(height: 2),
                    Center(
                      child: ReadersField(
                        card: card,
                        usage: _usage,
                        newReading: _newReading,
                        onChanged: (value) {
                          double? newReading = double.tryParse(value);
                          if (newReading == null) {
                            setState(() {
                              _usage = null;
                              _calculatedBill = null;
                              _beforeDatecalculation = null;
                              _afterDatecalculation = null;
                            });
                          } else {
                            double usage = newReading - card.cardPrevreading;
                            setState(() {
                              _newReading = newReading.toInt();
                              _usage = usage;
                            });
                            _updateBill(card, usage);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: ParticularsContainer(
                            card: card,
                            calculatedBill: _calculatedBill,
                            beforeDatecalculation: _beforeDatecalculation,
                            afterDatecalculation: _afterDatecalculation,
                            calculatedSCDisc: _calculatedSCDisc,
                            ftaxActivate: _ftaxActivate,
                            penaltyActivate: _penaltyActivate,
                            flatbill: _flatbill,
                            totalFlatbill:
                                (_flatbill ?? 0.0) + (card.cardArrears),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          bottomNavigationBar: SafeArea(
            child: BottomButtons(
              onPrint: handlePrintButton,
              onSave: handleSaveButton,
              onPrintFlat: handlePrintFlat,
              rateType: _rateType ?? 0,
            ),
          ),
        ),
        if (_isSaving)
          Container(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  void _showNoteDialog(BuildContext context) {
    if (_currentCard == null) return;
    final card = _currentCard!;
    final TextEditingController _noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.note_add_outlined,
                color: Colors.green.shade600, size: 22),
            const SizedBox(width: 8),
            const Text('Add Note',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.cardName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(card.cardAccno,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type your note here...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.green.shade400, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final text = _noteController.text.trim();
              if (text.isEmpty) return;
              final prefs = await PrefsModel.fetch();
              final note = ConsumerNoteModel(
                masCode: card.cardMasCode,
                noteText: text,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                readingDate: prefs?.billdate ?? '',
                readerName: prefs?.readername ?? '',
                zb: card.cardAccno.split('-').first,
              );
              await NotesHelper().insertNote(note);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note saved')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Note'),
          ),
          if (_noteActivate)
            ElevatedButton.icon(
              onPressed: () async {
                final text = _noteController.text.trim();
                if (text.isEmpty) return;
                final prefs = await PrefsModel.fetch();
                final note = ConsumerNoteModel(
                  masCode: card.cardMasCode,
                  noteText: text,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  readingDate: prefs?.billdate ?? '',
                  readerName: prefs?.readername ?? '',
                  zb: card.cardAccno.split('-').first,
                );
                await NotesHelper().insertNote(note);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note saved')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save Note'),
            ),
        ],
      ),
    );
  }

  /// AppBar widget.
  AppBar cardAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        '',
        style: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.pop(context, true);
        },
        child: Container(
          margin: const EdgeInsets.all(5),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/arrow-left.svg',
            height: 25,
            width: 25,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
        ),
      ),
      actions: [
        if (_noteActivate)
          GestureDetector(
            onTap: () {
              _showNoteDialog(context);
            },
            child: Container(
              margin: const EdgeInsets.all(10),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/icons/note.svg',
                height: 25,
                width: 25,
                colorFilter:
                    const ColorFilter.mode(Colors.green, BlendMode.srcIn),
              ),
            ),
          ),
      ],
    );
  }
}
