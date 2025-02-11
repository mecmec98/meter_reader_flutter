import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/helpers/calculatebill_helper.dart'; // Adjust the import path as needed

class TestBillingPage extends StatefulWidget {
  @override
  _TestBillingPageState createState() => _TestBillingPageState();
}

class _TestBillingPageState extends State<TestBillingPage> {
  // Text editing controller to capture usage input.
  final TextEditingController _usageController = TextEditingController();

  // Variable to hold the calculated bill result.
  String _resultText = '';

  // For testing, we use a fixed CSSSZ value.
  final String _csssz = "102";

  // Method to perform the calculation.
  Future<void> _calculateBill() async {
    // Get the usage value from the text field.
    final usageStr = _usageController.text;
    if (usageStr.isEmpty) {
      setState(() {
        _resultText = "Please enter a usage value.";
      });
      return;
    }
    int? usage = int.tryParse(usageStr);
    if (usage == null) {
      setState(() {
        _resultText = "Invalid usage value.";
      });
      return;
    }

    try {
      // Call the helper function to calculate the bill.
      double bill = await CalculatebillHelper.calculateBill(_csssz, usage);
      setState(() {
        _resultText = "Calculated Bill: P ${bill.toStringAsFixed(2)} Note: +25.00 from WMF";
      });
    } catch (e) {
      setState(() {
        _resultText = "Error calculating bill: $e";
      });
    }
  }

  @override
  void dispose() {
    _usageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Test Billing Formula"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Text field to enter the usage value.
            TextField(
              controller: _usageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter Usage",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            // Button to trigger the calculation.
            ElevatedButton(
              onPressed: _calculateBill,
              child: Text("Calculate Bill"),
            ),
            SizedBox(height: 20),
            // Text widget to display the result.
            Text(
              _resultText,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
