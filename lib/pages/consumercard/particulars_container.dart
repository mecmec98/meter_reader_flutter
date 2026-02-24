import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/models/consumercard_model.dart';

class ParticularsContainer extends StatelessWidget {
  final ConsumercardModel card;
  final double? calculatedBill;
  final double? beforeDatecalculation;
  final double? afterDatecalculation;
  final double? calculatedSCDisc;

  final bool ftaxActivate = true;
  const ParticularsContainer(
      {super.key,
      required this.card,
      required this.calculatedBill,
      required this.beforeDatecalculation,
      required this.afterDatecalculation,
      required this.calculatedSCDisc});

  @override
  Widget build(BuildContext context) {
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
                calculatedBill != null
                    ? calculatedBill!.toStringAsFixed(2)
                    : '0.00',
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          //will show up if there's a previous usage
          if (card.cardPreviousUsage > 0) ...[
            const Divider(color: Colors.grey, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Previous Usage'),
                Text(
                  card.cardPreviousUsage.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],

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
                  style: const TextStyle(fontWeight: FontWeight.w400)),
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
                    calculatedSCDisc != null
                        ? calculatedSCDisc!.toStringAsFixed(2)
                        : '0.00',
                    style: const TextStyle(fontWeight: FontWeight.w400)),
              ],
            ),
          ],
          if (ftaxActivate) ...[
            const Divider(color: Colors.grey, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Franchise Tax',
                  style: TextStyle(color: Colors.green),
                ),
                Text('${card.prefsFtax.toStringAsFixed(0)}%',
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
              Text((beforeDatecalculation ?? 0.0).toStringAsFixed(2),
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
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.orange)),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total After Due Date',
                  style: TextStyle(color: Colors.orange)),
              Text((afterDatecalculation ?? 0.0).toStringAsFixed(2),
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
}
