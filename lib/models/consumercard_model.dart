import 'package:meter_reader_flutter/helpers/database_helper.dart';

class ConsumercardModel {
  String cardName;
  String cardAccno;
  String cardAddress;
  String cardMeterno;
  String cardMeterbrand;
  String cardCodeRaw;
  String cardClassification; // Will hold the LTYPE value from the rates table.
  String
      cardMetersize; // Will hold the dynamic MSIZE value from the rates table.

  int cardPrevreading;
  int cardCurrreading;
  int cardId;
  int cardwithSeniorDisc;
  double cardSeniorDiscValue;

  double cardCurrbill;
  double cardWmf;
  int cardAvusage;
  double cardLessdisc;
  double cardArrears;
  double cardOthers;
  double cardTotalbdd;
  double cardPenalty;
  double cardTotaladd;
  double cardUsage;
  String cardprevReadingDate;
  String cardRefNo;
  String cardcurrentReadingDate;
  int cardPreviousUsage;

  String prefsDatedue;
  String prefsCutdate;
  String prefsBilldate;
  String prefsReadername;

  ConsumercardModel({
    required this.cardName,
    required this.cardAccno,
    required this.cardAddress,
    required this.cardMeterno,
    required this.cardMeterbrand,
    required this.cardCodeRaw,
    required this.cardClassification,
    required this.cardMetersize,
    required this.cardPrevreading,
    required this.cardCurrreading,
    required this.cardId,
    required this.cardwithSeniorDisc,
    required this.cardSeniorDiscValue,
    required this.cardCurrbill,
    required this.cardWmf,
    required this.cardAvusage,
    required this.cardLessdisc,
    required this.cardArrears,
    required this.cardOthers,
    required this.cardTotalbdd,
    required this.cardPenalty,
    required this.cardTotaladd,
    required this.cardUsage,
    required this.cardprevReadingDate,
    required this.cardRefNo,
    required this.cardcurrentReadingDate,
    required this.cardPreviousUsage,
    required this.prefsCutdate,
    required this.prefsDatedue,
    required this.prefsBilldate,
    required this.prefsReadername,
  });

  /// Asynchronously creates a ConsumercardModel from a database [map]
  /// and retrieves the additional rate data.
  ///
  /// For cardMetersize:
  ///   - The raw CLSSSZ value is used.
  ///   - The first two digits (e.g., "10" from "102") are used as the CODE.
  ///   - The last digit (e.g., "2") is used to determine the dynamic column (MSIZE2).
  static Future<ConsumercardModel> createFromMapWithRates(
      Map<String, dynamic> map, Map<String, dynamic> prefsMap) async {
    // Retrieve the raw CLSSSZ value.
    String rawClsssz = map['CLSSSZ'] ?? '';

    // Extract the first two digits as the class code.
    int classCode = 0;
    if (rawClsssz.length >= 2) {
      classCode = int.parse(rawClsssz.substring(0, 2));
    }

    // Use the last character as the suffix (if available).
    String suffix = rawClsssz.length >= 3 ? rawClsssz.substring(2, 3) : '';

    // Query the rates table using the class code.
    // This query should return a map that includes at least the LTYPE and MSIZE columns.
    Map<String, dynamic>? ratesData =
        await DatabaseHelper().getClassfromRates(classCode);

    // Use the LTYPE value from ratesData (or default to an empty string).
    String ltype = ratesData?['LTYPE'] ?? '';

    // For cardMetersize, dynamically retrieve the value from the column "MSIZE$suffix"
    String msize = ratesData?["MSIZE$suffix"] ?? '';

    return ConsumercardModel(
      cardId: map['_id'] is int ? map['_id'] as int : 0,
      cardCodeRaw: map['CLSSSZ'],
      cardName: map['NAME'] ?? '',
      // Construct account number as "ZB-CLSSSZ-ACC1" using the raw CLSSSZ value.
      cardAccno: '${map['ZB'] ?? ''}-$rawClsssz-${map['ACC1'] ?? ''}',
      cardAddress: map['ADDRESS'] ?? '',
      cardMeterno: map['MNO'] ?? '',
      cardMeterbrand: map['BRAND'] ?? '',
      // Instead of storing raw CLSSSZ, store the LTYPE from the rates table.
      cardClassification: ltype,
      // Store the dynamically retrieved MSIZE value.
      cardMetersize: msize,

      cardPrevreading: map['PREADING'] is int ? map['PREADING'] as int : 0,
      cardCurrreading: map['CREADING'] is int ? map['CREADING'] as int : 0,
      cardwithSeniorDisc:
          map['WITHSCDISC'] is int ? map['WITHSCDISC'] as int : 0,

      cardSeniorDiscValue:
          map['SCDISC'] != null ? (map['SCDISC'] as num).toDouble() / 100 : 0.0,
      cardCurrbill: map['AMOUNT'] != null
          ? (map['AMOUNT'] as num).toDouble() / 100
          : 0.0, // Set default; update if needed.
      cardLessdisc: 0, // Set default; update if needed.
      cardArrears: map['ARREARS'] != null
          ? (map['ARREARS'] as num).toDouble() / 100
          : 0.0,
      cardOthers:
          map['ARO'] != null ? (map['ARO'] as num).toDouble() / 100 : 0.0,
      cardWmf: map['WMF'] != null ? (map['WMF'] as num).toDouble() / 100 : 0.0,
      cardAvusage: map['AVE'] is int ? map['AVE'] as int : 0,
      cardTotalbdd: 0, // Set default; update if needed.
      cardPenalty: 0, // Set default; update if needed.
      cardTotaladd: 0, // Set default; update if needed.
      cardUsage: map['USAGE'] != null ? (map['USAGE'] as num).toDouble() : 0.0,
      cardPreviousUsage:
          map['PCUMUSED'] is int ? map['PCUMUSED'] as int : 0,

      cardprevReadingDate: map['MPRDGDT'] ?? '',
      cardcurrentReadingDate: map['MCRDGDT'] ?? '',
      cardRefNo: (map['REFNO'] ?? 0).toString(),

      prefsCutdate: prefsMap['cutdate'] ?? '',
      prefsDatedue: prefsMap['datedue'] ?? '',
      prefsBilldate: prefsMap['billdate'] ?? '',
      prefsReadername: prefsMap['meterreader'] ?? '',
    );
  }
}

/// Retrieves a ConsumercardModel by its ID.
Future<ConsumercardModel?> getConsumercardByID(int id) async {
  // Retrieve the card map from the database.
  final Map<String, dynamic>? cardMap = await DatabaseHelper().getCardByID(id);
  //Also Retrieve the prefs map from the database:
  final Map<String, dynamic>? prefsMap = await DatabaseHelper().getPrefsData();

  if (cardMap != null && prefsMap != null) {
    // Use the asynchronous factory method to create the model, including rate data.

    return ConsumercardModel.createFromMapWithRates(cardMap, prefsMap);
  } else {
    return null;
  }
}
