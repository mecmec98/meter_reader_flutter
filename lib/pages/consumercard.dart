import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';
import 'package:meter_reader_flutter/models/consumercard_model.dart'; // Make sure the path is correct
import 'package:meter_reader_flutter/helpers/calculatebill_helper.dart';
import 'package:intl/intl.dart';
import 'package:meter_reader_flutter/helpers/blueprinter_helper.dart';
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

  double? _usage;
  double? _calculatedBill;
  double? _beforeDatecalculation;
  double? _afterDatecalculation;
  double? _calculatedSCDisc;
  String scDiscLimitWarning = 'Limit Usage for Senior Citezen Discount';
  String? _currentDate =
      DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.now());

  bool _billUpdated = false;
  bool _isSaving = false;
  //String? _formattedDate =
  //    DateFormat('MM-dd-yyyy').format(DateTime.now().add(Duration(days: 15)));

  // Retrieve the card ID from the route arguments.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
  }

  // Handles the Print Button click event.
  Future<void> handlePrintButton() async {
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
        await updateMasterRecord(billStatePrinted);
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

    int billStateSaved = 1;
    await updateMasterRecord(billStateSaved);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> updateMasterRecord(int billStatind) async {
    //setState(() => _isSaving = true);
    // Ensure _newReading is set to card.cardCurrreading if null or 0
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

      int finalSCdisc = scDisc.toInt();
      int calculateBillInt = dbBill.toInt();
      int usageInt = _usage!.toInt();
      int penalty = 0;

      int isPosted = 1;
      int billStatus =
          billStatind; //indicator just 1 if only saved, 2 if saved and printed
      int? isNewReading = _newReading;
      String dateUpdated =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      Map<String, dynamic> updatedData = {
        'AMOUNT': calculateBillInt,
        'USAGE': usageInt,
        'POSTED': isPosted,
        'BILL_STAT': billStatus,
        'CREADING': isNewReading,
        'MCRDGDT': dateUpdated,
        'SCDISC': finalSCdisc,
        'PEN': penalty,
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
    setState(() => _isSaving = false);
  }

  Future<void> _printReceipt(ConsumercardModel card) async {
    final bluetoothHelper = context.read<BluePrinterHelper>();
    await bluetoothHelper.printReceipt(
      _currentDate.toString(),
      card.prefsDatedue.toString(),
      card.cardName,
      card.cardAddress,
      card.cardMeterno,
      card.cardMeterbrand,
      card.cardAccno,
      (_newReading ?? card.cardCurrreading)
          .toString(), // Use new reading if available
      card.cardPrevreading.toString(),
      (_usage ?? card.cardUsage).toString(), // Current usage from state
      (_calculatedBill ?? card.cardCurrbill)
          .toStringAsFixed(2), // Calculated bill from state
      card.cardWmf.toStringAsFixed(2),
      card.cardArrears,
      (_beforeDatecalculation ?? 0.0).toStringAsFixed(2),
      card.prefsCutdate.toString(),
      card.cardprevReadingDate,
      card.prefsBilldate,
      card.cardAvusage.toString(),
      card.cardOthers.toStringAsFixed(2),
      card.cardRefNo,
      card.prefsReadername,
      card.cardwithSeniorDisc,
      card.cardOthers.toStringAsFixed(2),
    );
  }

  /// Calls the billing helper and updates the _calculatedBill state.
  void _updateBill(ConsumercardModel card, double usage) async {
    try {
      // card.cardCodeRaw is used as the CSSSZ code.
      double bill = await CalculatebillHelper.calculateBill(
          card.cardCodeRaw, usage.toInt());
      double scDisc;
      if (card.cardwithSeniorDisc == 1 && _usage! < 30) {
        scDisc = bill * 0.05;
      } else {
        scDisc = 0.00;
      }
      double totalBeforeDue =
          (bill - scDisc) + card.cardArrears + card.cardOthers + card.cardWmf;
      double totalAfterDue = totalBeforeDue * 1.05;

      setState(() {
        _calculatedBill = bill;
        _beforeDatecalculation = totalBeforeDue;
        _afterDatecalculation = totalAfterDue;
        _calculatedSCDisc = scDisc;
      });
    } catch (e) {
      print("Error calculating bill: $e");
      setState(() {
        _calculatedBill = null;
        _beforeDatecalculation = null;
        _afterDatecalculation = null;
        _calculatedSCDisc = null;
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _currentCard?.cardId != card.cardId) {
                    setState(() {
                      _currentCard = card;
                    });
                  }
                });
                if (!_billUpdated && card.cardUsage != 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateBill(card, card.cardUsage);
                    setState(() {
                      _usage = card.cardUsage;
                      _billUpdated = true;
                    });
                  });
                }
                return Column(
                  children: [
                    const SizedBox(height: 10),
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

  /// AppBar widget.
  AppBar cardAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Water Consumer',
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
          margin: const EdgeInsets.all(10),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/arrow-left.svg',
            height: 25,
            width: 25,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
