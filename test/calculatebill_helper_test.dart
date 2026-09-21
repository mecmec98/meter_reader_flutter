import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reader_flutter/helpers/calculatebill_helper.dart';

void main() {
  test('calculateBillBreakdownFromRates returns tiered breakdown for a 20-unit bill', () {
    final result = CalculatebillHelper.calculateBillBreakdownFromRates(
      minCharge: 1500,
      bulk1: 200,
      bulk2: 300,
      bulk3: 400,
      bulk4: 500,
      usage: 20,
    );

    expect(result.total, 35.0);
    expect(result.tiers.length, 2);
    expect(result.tiers[0].label, '1-10');
    expect(result.tiers[0].amount, 15.0);
    expect(result.tiers[1].label, '11-20');
    expect(result.tiers[1].amount, 20.0);
  });
}
