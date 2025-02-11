import 'package:meter_reader_flutter/helpers/database_helper.dart';

class CalculatebillHelper {
  static Future<double> calculateBill(String clsssz, int usage) async {
    // Validate that CSSSZ has at least 3 characters.
    if (clsssz.length < 3) {
      throw Exception("Invalid CSSSZ code: $clsssz");
    }

    // 1. Extract the row identifier from the first two characters.
    int codePrefix = int.parse(clsssz.substring(0, 2)); // e.g., "102" -> 10

    // 2. Use the last character as the suffix.
    String suffix = clsssz.substring(2, 3); // e.g., "102" -> "2"

    // 3. Build the dynamic column names.
    String minCol = "MIN$suffix"; // e.g., MIN2
    String bulk1Col = "BULK1$suffix"; // e.g., BULK12
    String bulk2Col = "BULK2$suffix"; // e.g., BULK22
    String bulk3Col = "BULK3$suffix"; // e.g., BULK32

    // 4. Query the rates table for the row with CODE = codePrefix.
    final db = await DatabaseHelper().database;
    List<Map<String, dynamic>> result = await db.query(
      'rates',
      columns: [minCol, bulk1Col, bulk2Col, bulk3Col],
      where: 'CODE = ?',
      whereArgs: [codePrefix],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception("Rates not found for code $codePrefix");
    }

    Map<String, dynamic> rates = result.first;
    double minCharge = (rates[minCol] as num).toDouble();
    double bulk1 = (rates[bulk1Col] as num).toDouble();
    double bulk2 = (rates[bulk2Col] as num).toDouble();
    double bulk3 = (rates[bulk3Col] as num).toDouble();

    double finalValue = 0.0;

    // 5. Calculate the final bill based on the usage.
    if (usage <= 10) {
      // Usage less than or equal to 10: only the minimum charge applies.
      finalValue = minCharge / 100;
    } else if (usage <= 20) {
      // For usage 11 to 20:
      // finalValue = MIN$suffix + ((BULK1$suffix/100) * (usage - 10))
      int extraUnits = usage - 10; // For usage = 20, extraUnits = 10.
      finalValue = minCharge / 100 + ((bulk1 / 100) * extraUnits);
    } else if (usage <= 30) {
      // For usage 21 to 30:
      // finalValue = MIN$suffix + ((BULK1$suffix/100) * 10) + ((BULK2$suffix/100) * (usage - 20))
      int extraUnits = usage - 20; // For usage = 30, extraUnits = 10.
      finalValue =
          minCharge / 100 + ((bulk1 / 100) * 10) + ((bulk2 / 100) * extraUnits);
    } else if (usage <= 40) {
      // For usage 31 to 40:
      // finalValue = MIN$suffix + ((BULK1$suffix/100) * 10) + ((BULK2$suffix/100) * 10) + ((BULK3$suffix/100) * (usage - 30))
      int extraUnits = usage - 30; // For usage = 40, extraUnits = 10.
      finalValue = minCharge / 100 +
          ((bulk1 / 100) * 10) +
          ((bulk2 / 100) * 10) +
          ((bulk3 / 100) * extraUnits);
    } else {
      // If usage exceeds 40, you can extend this logic.
      // For now, we cap the calculation at 40.
      finalValue = minCharge / 100 +
          ((bulk1 / 100) * 10) +
          ((bulk2 / 100) * 10) +
          ((bulk3 / 100) * 10);
    }

    return finalValue;
  }
}
