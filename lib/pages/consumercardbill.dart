import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';
import 'package:meter_reader_flutter/models/consumercard_model.dart'; // Make sure the path is correct
import 'package:meter_reader_flutter/helpers/calculatebill_helper.dart';
import 'package:intl/intl.dart';

//Card after Printbilllist
class ConsumercardBill extends StatefulWidget {
  // ignore: use_super_parameters
  const ConsumercardBill({Key? key}) : super(key: key);

  @override
  State<ConsumercardBill> createState() => _ConsumercardBillState();
}

class _ConsumercardBillState extends State<ConsumercardBill> {
  // Future that retrieves the consumer card from the database.
  int? _cardId;
  int? _newReading;
  Future<ConsumercardModel?>? _cardFuture;
  double? _usage;
  double? _calculatedBill;
  double? _beforeDatecalculation;
  double? _afterDatecalculation;
  bool _billUpdated =
      false;
  String? _formattedDate =
      DateFormat('MM-dd-yyyy').format(DateTime.now().add(Duration(days: 15)));

  // Retrieve the card ID from the route arguments.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _cardId = args;
      _cardFuture = getConsumercardByID(_cardId!);
      print(_formattedDate);
    } else {
      // Optional: fallback if no valid argument is passed.
      Navigator.pushNamed(context, '/');
    }
  }

  @override
  void initState() {
    super.initState();
    // For testing, we previously used card id 1.
    // Now, _cardFuture is set in didChangeDependencies.
  }

  /// Calls the billing helper and updates the _calculatedBill state.
  void _updateBill(ConsumercardModel card, double usage) async {
    try {
      // card.cardCodeRaw is used as the CSSSZ code.
      double bill = await CalculatebillHelper.calculateBill(
          card.cardCodeRaw, usage.toInt());
      double totalBeforeDue =
          bill + card.cardArrears + 0.0 + 0.0 + card.cardWmf;
      double totalAfterDue = totalBeforeDue * 1.05;

      setState(() {
        _calculatedBill = bill;
        _beforeDatecalculation = totalBeforeDue;
        _afterDatecalculation = totalAfterDue;
      });
    } catch (e) {
      print("Error calculating bill: $e");
      setState(() {
        _calculatedBill = null;
        _beforeDatecalculation = null;
        _afterDatecalculation = null;
      });
    }
  }

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

            // CHANGED: Automatically update bill if card.cardUsage is not 0 and _usage hasn't been set.
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

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Center(child: userInformationCard(card)),
                  const SizedBox(height: 2),
                  Center(child: readersField(card)),
                  const SizedBox(height: 2),
                  Center(child: particularsContainer(card)),
                ],
              ),
            );
          }
        },
      ),
      bottomNavigationBar: bottomButtons(),
    );
  }

  /// Widget that displays the user information card.
  Widget userInformationCard(ConsumercardModel card) {
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
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 5),
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
          Column(
            children: [
              // First Row: Meter No. and Meter Brand
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        card.cardMeterno,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w400,
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
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: card.cardCurrreading.toString(),
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            onChanged: (value) {
              double? newReading = double.tryParse(value);
              if (newReading == null || newReading <= card.cardPrevreading) {
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
              fontWeight: FontWeight.w400,
              fontSize: 10,
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
              ),
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
            children: const [
              Text('Others'),
              Text('0.00', style: TextStyle(fontWeight: FontWeight.w400)),
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
          ),
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
              const Text('Date Due', style: TextStyle(color: Colors.red)),
              Text(_formattedDate ?? '',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.red)),
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
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/printface',
                arguments: _cardId,
              );
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
              print('I(Save) got pressed');
              if (_cardId != null &&
                  _calculatedBill != null &&
                  _usage != null &&
                  _newReading != null) {
                // CHANGED: Convert calculated bill to cents and then to int.
                double dbBill = _calculatedBill! * 100;
                int calculateBillInt = dbBill.toInt();
                int usageInt = _usage!.toInt();
                int isPosted = 1;
                int? isNewReading = _newReading;

                Map<String, dynamic> updatedData = {
                  'AMOUNT': calculateBillInt,
                  'USAGE': usageInt,
                  'POSTED': isPosted,
                  'CREADING': isNewReading
                };
                try {
                  int count = await DatabaseHelper()
                      .updateMasterData(_cardId!, updatedData);
                  if (!mounted) return;
                  if (count > 0) {
                    // CHANGED: Fetch the updated record for testing
                    Map<String, dynamic>? updatedRecord =
                        await DatabaseHelper().getMasterByID(_cardId!);
                    print("Updated record data: $updatedRecord");
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Record updated successfully!')),
                    );
                    // CHANGED: Refresh the UI by reassigning _cardFuture.
                    setState(() {
                      _cardFuture = getConsumercardByID(_cardId!);
                    });
                    //Navigator.pushNamed(context, '/postmeterreading');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Update failed.')),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving the record: $e')),
                  );
                }
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
        'Post Meter Reading',
        style: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.pop(context);
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
