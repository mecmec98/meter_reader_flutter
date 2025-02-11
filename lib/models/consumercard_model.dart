import 'package:meter_reader_flutter/helpers/database_helper.dart';

class ConsumercardModel {
  String cardName;
  String cardAccno;
  String cardAddress;
  String cardMeterno;
  String cardMeterbrand;
  String cardClassification;
  String cardMetersize;
  int cardPrevreading;
  int cardCurrreading;
  double cardCurrbill;
  double cardLessdisc;
  double cardArrears;
  double cardOthers;
  double cardTotalbdd;
  double cardPenalty;
  double cardTotaladd;

  ConsumercardModel({
    required this.cardName,
    required this.cardAccno,
    required this.cardAddress,
    required this.cardMeterno,
    required this.cardMeterbrand,
    required this.cardClassification,
    required this.cardMetersize,
    required this.cardPrevreading,
    required this.cardCurrreading,
    required this.cardCurrbill,
    required this.cardLessdisc,
    required this.cardArrears,
    required this.cardOthers,
    required this.cardTotalbdd,
    required this.cardPenalty,
    required this.cardTotaladd,
  });

  static Future<ConsumercardModel> createFromMapWithRates(
      Map<String, dynamic> map) async {
    // Retrieve the raw CLSSSZ value from the map.
    String rawClsssz = map['CLSSSZ'] ?? '';

    // Extract the first two digits as the class code.
    int classCode = 0;
    if (rawClsssz.length >= 2) {
      classCode = int.parse(rawClsssz.substring(0, 2));
    }

    // Query the rates table using the class code.
    Map<String, dynamic>? ratesData =
        await DatabaseHelper().getClassfromRates(classCode);

    // Use the LTYPE value from ratesData, or fall back to an empty string.
    String ltype = ratesData?['LTYPE'] ?? '';

    return ConsumercardModel(
      cardName: map['NAME'] ?? '',
      // Construct account number as "ZB-CLSSSZ-ACC1" using the raw CLSSSZ value.
      cardAccno: '${map['ZB'] ?? ''}-$rawClsssz-${map['ACC1'] ?? ''}',
      cardAddress: map['ADDRESS'] ?? '',
      cardMeterno: map['MNO'] ?? '',
      cardMeterbrand: map['BRAND'] ?? '',
      // Instead of storing raw CLSSSZ, store the LTYPE from rates.
      cardClassification: ltype,
      cardMetersize: '', // Not provided by the query.
      cardPrevreading: map['PREADING'] is int ? map['PREADING'] as int : 0,
      cardCurrreading: map['CREADING'] is int ? map['CREADING'] as int : 0,
      cardCurrbill: 0, // Set default; you can calculate if needed.
      cardLessdisc: 0, // Set default; adjust if needed.
      cardArrears: map['ARREARS'] != null
          ? (map['ARREARS'] as num).toDouble() / 100
          : 0.0,
      cardOthers:
          map['ARO'] != null ? (map['ARO'] as num).toDouble() / 100 : 0.0,
      cardTotalbdd: 0, // Set default; adjust if needed.
      cardPenalty: 0, // Set default; adjust if needed.
      cardTotaladd: 0, // Set default; adjust if needed.
    );
  }
}

Future<ConsumercardModel?> getConsumercardByID(int id) async {
  // Call the helper method that returns a Map from the database.
  final Map<String, dynamic>? cardMap = await DatabaseHelper().getCardByID(id);

  if (cardMap != null) {
    // Convert the map to a ConsumercardModel instance.
    return ConsumercardModel.createFromMapWithRates(cardMap);
  } else {
    return null;
  }
}
