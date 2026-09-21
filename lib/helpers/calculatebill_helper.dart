import 'package:meter_reader_flutter/helpers/database_helper.dart';

class BillTier {
  final String label;
  final double amount;
  final int units;
  final double ratePerUnit;

  const BillTier({
    required this.label,
    required this.amount,
    required this.units,
    required this.ratePerUnit,
  });
}

class BillBreakdown {
  final double total;
  final List<BillTier> tiers;

  const BillBreakdown({required this.total, required this.tiers});
}

class CalculatebillHelper {
  static BillBreakdown calculateBillBreakdownFromRates({
    required double minCharge,
    required double bulk1,
    required double bulk2,
    required double bulk3,
    required double bulk4,
    required int usage,
  }) {
    final tiers = <BillTier>[];
    double total = 0;

    const firstBlockLimit = 10;
    const secondBlockLimit = 20;
    const thirdBlockLimit = 30;
    const fourthBlockLimit = 40;

    final minAmount = minCharge / 100;
    total += minAmount;
    tiers.add(BillTier(
      label: 'Minimum',
      amount: minAmount,
      units: 0,
      ratePerUnit: 0,
    ));

    if (usage > firstBlockLimit) {
      final secondBlockUnits =
          (usage > secondBlockLimit ? secondBlockLimit : usage) - firstBlockLimit;
      final secondBlockAmount = (bulk1 / 100) * secondBlockUnits;
      total += secondBlockAmount;
      tiers.add(BillTier(
        label: '11-20m3',
        amount: secondBlockAmount,
        units: secondBlockUnits,
        ratePerUnit: bulk1 / 100,
      ));
    }

    if (usage > secondBlockLimit) {
      final thirdBlockUnits =
          (usage > thirdBlockLimit ? thirdBlockLimit : usage) - secondBlockLimit;
      final thirdBlockAmount = (bulk2 / 100) * thirdBlockUnits;
      total += thirdBlockAmount;
      tiers.add(BillTier(
        label: '21-30m3',
        amount: thirdBlockAmount,
        units: thirdBlockUnits,
        ratePerUnit: bulk2 / 100,
      ));
    }

    if (usage > thirdBlockLimit) {
      final fourthBlockUnits =
          (usage > fourthBlockLimit ? fourthBlockLimit : usage) - thirdBlockLimit;
      final fourthBlockAmount = (bulk3 / 100) * fourthBlockUnits;
      total += fourthBlockAmount;
      tiers.add(BillTier(
        label: '31-40m3',
        amount: fourthBlockAmount,
        units: fourthBlockUnits,
        ratePerUnit: bulk3 / 100,
      ));
    }

    if (usage > fourthBlockLimit) {
      final remainingUnits = usage - fourthBlockLimit;
      final remainingAmount = (bulk4 / 100) * remainingUnits;
      total += remainingAmount;
      tiers.add(BillTier(
        label: '41+m3',
        amount: remainingAmount,
        units: remainingUnits,
        ratePerUnit: bulk4 / 100,
      ));
    }

    return BillBreakdown(total: total, tiers: tiers);
  }

  static Future<BillBreakdown> calculateBillBreakdown(
      String clsssz, int usage) async {
    if (clsssz.length < 3) {
      throw Exception("Invalid CSSSZ code: $clsssz");
    }

    int codePrefix = int.parse(clsssz.substring(0, 2));
    String suffix = clsssz.substring(2, 3);

    String minCol = "MIN$suffix";
    String bulk1Col = "BULK1$suffix";
    String bulk2Col = "BULK2$suffix";
    String bulk3Col = "BULK3$suffix";
    String bulk4Col = "BULK4$suffix";

    final db = await DatabaseHelper().database;
    List<Map<String, dynamic>> result = await db.query(
      'rates',
      columns: [minCol, bulk1Col, bulk2Col, bulk3Col, bulk4Col],
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
    double bulk4 = (rates[bulk4Col] as num).toDouble();

    return calculateBillBreakdownFromRates(
      minCharge: minCharge,
      bulk1: bulk1,
      bulk2: bulk2,
      bulk3: bulk3,
      bulk4: bulk4,
      usage: usage,
    );
  }

  static Future<double> calculateBill(String clsssz, int usage) async {
    final breakdown = await calculateBillBreakdown(clsssz, usage);
    return breakdown.total;
  }

  static Future<double> getFlatbill() async {
    final db = await DatabaseHelper().database;
    List<Map<String, dynamic>> result = await db.query(
      'rates',
      columns: ['FLAT2'],
      where: 'CODE = ? AND _id = ?',
      whereArgs: [20, 2],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception("Could not find flat rate");
    }
    //divide by 100 first then convert the invt value to double
    final raw = result.first['FLAT2'];
    final flatbill = (raw is int ? raw.toDouble() : raw as double) / 100;
    return flatbill;
  }
}
