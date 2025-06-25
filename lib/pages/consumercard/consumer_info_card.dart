import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/models/consumercard_model.dart';

class ConsumerInfoCard extends StatelessWidget {
  final ConsumercardModel card;
  const ConsumerInfoCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            card.cardName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          Text(
            card.cardAccno,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 3),
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
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Column(
              children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.cardClassification,
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
                          card.cardMetersize,
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
}
