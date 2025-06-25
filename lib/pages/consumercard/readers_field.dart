import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/models/consumercard_model.dart';

class ReadersField extends StatelessWidget {
  final ConsumercardModel card;
  final double? usage;
  final int? newReading;
  final Function(String) onChanged;
  const ReadersField({super.key, required this.card, required this.usage, required this.newReading, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(
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
                  borderSide: const BorderSide(color: Colors.blue)),
            ),
            onChanged: onChanged,
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
                    usage != null ? usage!.toStringAsFixed(2) : '0.00',
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
}
