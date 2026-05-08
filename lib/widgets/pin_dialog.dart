import 'package:flutter/material.dart';

const String _defaultPin = '1981';

Future<bool> showPinDialog(BuildContext context) async {
  final controller = TextEditingController();

  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      bool hasError = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Enter PIN',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This area is restricted. Enter your PIN to continue.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  autofocus: true,
                  onSubmitted: (_) => _verify(
                      context, setState, controller, () => hasError = true),
                  decoration: InputDecoration(
                    hintText: '••••',
                    counterText: '',
                    errorText: hasError ? 'Incorrect PIN. Try again.' : null,
                    prefixIcon: const Icon(Icons.pin_outlined,
                        color: Colors.blue, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              ElevatedButton(
                onPressed: () => _verify(
                    context, setState, controller, () => hasError = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  //controller.dispose();
  return result ?? false;
}

void _verify(
  BuildContext context,
  StateSetter setState,
  TextEditingController controller,
  VoidCallback setError,
) {
  if (controller.text == _defaultPin) {
    Navigator.of(context).pop(true);
  } else {
    setState(() => setError());
    controller.clear();
  }
}