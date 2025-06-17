import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';
import 'package:meter_reader_flutter/models/consumercard_model.dart'; // Make sure the path is correct
import 'package:meter_reader_flutter/helpers/calculatebill_helper.dart';
import 'package:intl/intl.dart';
import 'package:meter_reader_flutter/helpers/blueprinter_helper.dart';
import 'package:provider/provider.dart';

//Card after postmeter list
class Consumercard extends StatefulWidget {
  // ignore: use_super_parameters
  const Consumercard({Key? key}) : super(key: key);

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

  Future<bool> updateMasterRecord(int billStatind) async {
    if (_currentCard == null || _cardId == null) return false;

    final newReading = _newReading ?? _currentCard!.cardCurrreading;

    if (_calculatedBill == null ||
        _usage == null ||
        _calculatedSCDisc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing billing data.')),
      );
      return false;
    }

    final updatedData = {
      'AMOUNT': (_calculatedBill! * 100).toInt(),
      'USAGE': _usage!.toInt(),
      'POSTED': 1,
      'BILL_STAT': billStatind,
      'CREADING': newReading,
      'MCRDGDT': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'SCDISC': (_calculatedSCDisc! * 100).toInt(),
      'PEN': 0,
    };

    try {
      final count =
          await DatabaseHelper().updateMasterData(_cardId!, updatedData);
      if (!mounted) return false;
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record updated successfully!')),
        );
        setState(() {
          _cardFuture = getConsumercardByID(_cardId!);
        });
        _currentCard = await getConsumercardByID(_cardId!);
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update failed.')),
        );
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving the record: $e')),
      );
      return false;
    }
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
  /// dont use usage
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
    return Scaffold(
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
            // Model loaded from the database.
            final card = snapshot.data!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _currentCard?.cardId != card.cardId) {
                setState(() {
                  _currentCard = card;
                });
              }
            });
            // Automatically update bill if card.cardUsage is not 0 and _usage hasn't been set.
            if (!_billUpdated && card.cardUsage != 0) {
              // Use a post-frame callback to avoid calling setState during build.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateBill(card, card.cardUsage);
                // Mark that the update has been done and set _usage
                setState(() {
                  _usage = card.cardUsage;
                  _billUpdated = true;
                });
              });
            }

            return Column(
              children: [
                const SizedBox(height: 10),
                Center(child: consomerInformationCard(card)),
                const SizedBox(height: 2),
                Center(child: readersField(card)),
                const SizedBox(height: 2),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(child: particularsContainer(card)),
                  ),
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: SafeArea(child: bottomButtons()),
    );
  }

  /// Widget that displays the user information card.
  Widget consomerInformationCard(ConsumercardModel card) {
    return Container(
      width: 350,
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Card Name
          Text(
            card.cardName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          // Account Number (constructed from ZB-CLSSSZ-ACC1)
          Text(
            card.cardAccno,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 3),
          // Address
          Text(
            card.cardAddress,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.grey, thickness: 0.5),
          const SizedBox(height: 10),
          // Additional information rows
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Column(
              children: [
                // First Row: Meter No. and Meter Brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.cardMeterno,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                        const Text(
                          'Meter no.',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color.fromARGB(255, 47, 48, 49),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          card.cardMeterbrand,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.blue,
                          ),
                        ),
                        const Text(
                          'Meter Brand',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color.fromARGB(255, 47, 48, 49),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Second Row: Classification and Meter Size
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.cardClassification, // LTYPE from rates
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w400,
                            color: Colors.blue,
                          ),
                        ),
                        const Text(
                          'Classification',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color.fromARGB(255, 47, 48, 49),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          card.cardMetersize, // MSIZE value from rates (dynamic)
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w400,
                            color: Colors.blue,
                          ),
                        ),
                        const Text(
                          'Meter Size',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color.fromARGB(255, 47, 48, 49),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget for the reading fields.
  Widget readersField(ConsumercardModel card) {
    return Container(
      padding: const EdgeInsets.only(top: 5, bottom: 10, left: 40, right: 40),
      child: Column(
        children: [
          const Text(
            'Current Reading',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w600, fontSize: 20),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: card.cardCurrreading.toString(),
              hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Colors.blue)),
            ),
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
          const SizedBox(height: 12),
          const Text(
            'Previous Reading',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            readOnly: true,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: card.cardPrevreading.toString(),
              hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 255, 250, 250),
                  fontWeight: FontWeight.w500,
                  fontSize: 20),
              filled: true,
              fillColor: Colors.blue,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    card.cardAvusage.toStringAsFixed(2),
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 20),
                  ),
                  const Text('Average Usage')
                ],
              ),
              Column(
                children: [
                  Text(
                    _usage != null ? _usage!.toStringAsFixed(2) : '0.00',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 20),
                  ),
                  const Text('Current Usage')
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  /// Widget for displaying billing particulars.
  Widget particularsContainer(ConsumercardModel card) {
    return Container(
      width: 320,
      padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Current Bill'),
              Text(
                _calculatedBill != null
                    ? _calculatedBill!.toStringAsFixed(2)
                    : '0.00',
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Arrears'),
              Text(card.cardArrears.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w400)),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Others'),
              Text(card.cardOthers.toStringAsFixed(2),
                  style: TextStyle(fontWeight: FontWeight.w400)),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Water Maintenance Fee'),
              Text(card.cardWmf.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w400)),
            ],
          ), //Will only show if card.cardwithSeniorDisc == 1
          if (card.cardwithSeniorDisc == 1) ...[
            const Divider(color: Colors.grey, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Senior Citizen Discount',
                  style: TextStyle(color: Colors.green),
                ),
                Text(
                    _calculatedSCDisc != null
                        ? _calculatedSCDisc!.toStringAsFixed(2)
                        : '0.00',
                    style: const TextStyle(fontWeight: FontWeight.w400)),
              ],
            ),
          ],
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Before Due Date',
                  style: TextStyle(color: Colors.blue)),
              Text((_beforeDatecalculation ?? 0.0).toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Penalty after due Date',
                  style: TextStyle(color: Colors.red)),
              Text('5%', style: TextStyle(fontWeight: FontWeight.w400)),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Date Due', style: TextStyle(color: Colors.orange)),
              Text(card.prefsDatedue,
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.orange)),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total After Due Date',
                  style: TextStyle(color: Colors.orange)),
              Text((_afterDatecalculation ?? 0.0).toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Disconnection Date',
                  style: TextStyle(color: Colors.red)),
              Text(card.prefsCutdate,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget for bottom navigation buttons.
  Widget bottomButtons() {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () async {
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
                    await _printReceipt(_currentCard!);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bill Printed')),
                    );
                    Navigator.pop(context, true);
                  } catch (e) {
                    bluetoothHelper.connected = false;
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Printer disconnected during print!')),
                    );
                  }
                }
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Printer not connected!')),
                );
              }
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.blue),
              padding: WidgetStateProperty.all<EdgeInsets>(
                const EdgeInsets.only(top: 10, bottom: 6, left: 60, right: 60),
              ),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
              ),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/icons/print.svg',
                  height: 20,
                  width: 20,
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
                const SizedBox(height: 1),
                const Text('Print',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                int billStateSaved = 1;
                final success = await updateMasterRecord(billStateSaved);
                if (!mounted) return;
                if (success) {
                  Navigator.pop(context, true);
                }
                // If not successful, do not pop or show extra message (already handled)
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.green),
              padding: WidgetStateProperty.all<EdgeInsets>(
                const EdgeInsets.only(top: 10, bottom: 6, left: 60, right: 60),
              ),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
              ),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/icons/save.svg',
                  height: 20,
                  width: 20,
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
                const SizedBox(height: 1),
                const Text('Save',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
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
