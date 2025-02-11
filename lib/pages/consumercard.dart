import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
//import 'package:meter_reader_flutter/helpers/database_helper.dart';
import 'package:meter_reader_flutter/models/consumercard_model.dart'; // Make sure the path is correct

class Consumercard extends StatefulWidget {
  const Consumercard({super.key});

  @override
  State<Consumercard> createState() => _ConsumercardState();
}

class _ConsumercardState extends State<Consumercard> {
  // Future that retrieves the consumer card from the database.
  Future<ConsumercardModel?>? _cardFuture;

  @override
  void initState() {
    super.initState();
    // For testing, we use card id 1.
    _cardFuture = getConsumercardByID(1);
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
  /// For example, current reading and previous reading.
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
            decoration: InputDecoration(
              // For testing, we display the current bill as a hint.
              hintText: card.cardCurrbill.toString(),
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
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
        ],
      ),
    );
  }

  /// Widget for displaying billing particulars.
  /// (You can later integrate a calculation from a billing helper.)
  Widget particularsContainer(ConsumercardModel card) {
    return Container(
      width: 320,
      padding: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Current Bill'),
              Text(
                '252.00', // Replace with calculation result if available.
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Less Discount'),
              Text(
                '0.00',
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Arrears'),
              Text(
                card.cardArrears.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Others'),
              Text(
                '0.00',
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Total Before Due Date',
                style: TextStyle(color: Colors.blue),
              ),
              Text(
                '504.00',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Penalty',
                style: TextStyle(color: Colors.red),
              ),
              Text(
                '0.00',
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Total After Due Date',
                style: TextStyle(color: Colors.green),
              ),
              Text(
                '504.00',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
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
              // TODO: Implement Print action.
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.blue),
              padding: WidgetStateProperty.all<EdgeInsets>(
                const EdgeInsets.only(top: 15, bottom: 15, left: 60, right: 60),
              ),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SvgPicture.asset(
                  'assets/icons/print.svg',
                  height: 20,
                  width: 20,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Print',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement Save action.
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.green),
              padding: WidgetStateProperty.all<EdgeInsets>(
                const EdgeInsets.only(top: 15, bottom: 15, left: 60, right: 60),
              ),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SvgPicture.asset(
                  'assets/icons/save.svg',
                  height: 20,
                  width: 20,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
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
          Navigator.pushNamed(context, '/postmeterreading');
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
