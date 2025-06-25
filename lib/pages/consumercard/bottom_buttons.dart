import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomButtons extends StatelessWidget {
  final VoidCallback onPrint;
  final VoidCallback onSave;

  const BottomButtons({
    super.key,
    required this.onPrint,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: onPrint,
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
            onPressed: onSave,
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
}
