import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:meter_reader_flutter/models/consumercard_model.dart';
//import 'package:meter_reader_flutter/helpers/database_helper.dart';

class Printface extends StatefulWidget {
  // ignore: use_super_parameters
  const Printface({Key? key}) : super(key: key);

  @override
  State<Printface> createState() => _PrintfaceState();
}

class _PrintfaceState extends State<Printface> {
  Future<ConsumercardModel?>? _cardFuture;
  //String? _formattedDate = DateFormat('MM-dd-yyyy').format(DateTime.now().add(Duration(days: 15)));
    int? _cardId;


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
    // For example, retrieve the card with id 1.
    //_cardFuture = getConsumercardByID(8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: printAppbarface(context),
      body: FutureBuilder<ConsumercardModel?>(
        future: _cardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading card'));
          }
          if (snapshot.data == null) {
            return const Center(child: Text('No card data found'));
          }
          ConsumercardModel card = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: receiptHeader(card)),
                    receiptConsumer(card),
                    recieptBody(card),
                    receiptFooter(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Example header that displays static text along with dynamic dates.
  Widget receiptHeader(ConsumercardModel card) {
    // For demonstration, assume bill release is today.
    DateTime billRelease = DateTime.now();
    DateTime dueDate = billRelease.add(const Duration(days: 15));
    String formattedDueDate = DateFormat('MM/dd/yyyy').format(dueDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Dapitan City Water District',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const Center(child: Text('Lorem Ipsum')),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'BILLING STATEMENT',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
        // Displaying month and period statically or based on card data if available.
        const Text('For the month of January 2025'),
        // For example, using the current date and time.
        Text(
            'Date Printed: ${DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.now())}'),
        // Period covered can also be dynamic.
        const Text('Period Covered: 1/17/2025-02/12/2025'),
        const SizedBox(height: 5),
        const Divider(color: Colors.grey, thickness: 0.5),
        // Show calculated due date.
        Text('DUE DATE: $formattedDueDate',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w300)),
      ],
    );
  }

  // Display consumer details using the card model.
  Widget receiptConsumer(ConsumercardModel card) {
    return Container(
      padding: const EdgeInsets.only(top: 1, bottom: 1),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.cardName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          Text(
            card.cardAddress,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Meter No. ${card.cardMeterno}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Meter Brand: ${card.cardMeterbrand}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 5),
          const Divider(color: Colors.grey, thickness: 0.5),
        ],
      ),
    );
  }

  // Display billing details using card values.
  Widget recieptBody(ConsumercardModel card) {
    double totalDue = card.cardCurrbill + card.cardWmf + card.cardArrears;
    double totalAfterDue = totalDue * 1.05;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Column(
        children: [
          _buildRow('Previous Reading', card.cardPrevreading.toString()),
          _buildRow('Current Reading', card.cardCurrreading.toString()),
          _buildRow('Usage', card.cardUsage.toStringAsFixed(2)),
          const Divider(color: Colors.grey, thickness: 0.5),
          _buildRow('Water Bill', card.cardCurrbill.toStringAsFixed(2)),
          _buildRow('Water Maintenance Fee', card.cardWmf.toStringAsFixed(2)),
          _buildRow('Arrears/Advance', card.cardArrears.toStringAsFixed(2)),
          const SizedBox(height: 2),
          _buildRow(
              'TOTAL DUE',
              totalDue
                  .toStringAsFixed(2) // Replace with actual calculation
              ),
          const Divider(color: Colors.grey, thickness: 0.5),
          // Optionally, if you want to show additional charges after due date.
          _buildRow('TOTAL AFTER DUE DATE',
              totalAfterDue.toStringAsFixed(2) // Replace with actual calculation if available
              ),
          const Divider(color: Colors.grey, thickness: 0.5),
        ],
      ),
    );
  }

  // Simple helper to create a row with two texts.
  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        )
      ],
    );
  }

  // Static footer
  Widget receiptFooter() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(1),
        child: const Text(
          'Other Messages and Announcements',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// The app bar remains largely unchanged.
AppBar printAppbarface(BuildContext context) {
  return AppBar(
    title: const Text(
      'Print Bill Sample',
      style: TextStyle(
        color: Colors.black,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    centerTitle: true,
    leading: GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/');
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
