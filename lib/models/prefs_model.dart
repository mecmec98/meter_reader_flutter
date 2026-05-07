import 'package:meter_reader_flutter/helpers/database_helper.dart';

class PrefsModel {
  final String cutdate;
  final String datedue;
  final String billdate;
  final String readername;
  final double ftax;
  final double penper;

  PrefsModel({
    required this.cutdate,
    required this.datedue,
    required this.billdate,
    required this.readername,
    required this.ftax,
    required this.penper,
  });

  static Future<PrefsModel?> fetch() async {
    final Map<String, dynamic>? prefsMap =
        await DatabaseHelper().getPrefsData();

    if (prefsMap == null) return null;

    return PrefsModel(
      cutdate: prefsMap['cutdate'] ?? '',
      datedue: prefsMap['datedue'] ?? '',
      billdate: prefsMap['billdate'] ?? '',
      readername: prefsMap['meterreader'] ?? '',
      ftax: prefsMap['ftaxbill'] != null
          ? (prefsMap['ftaxbill'] as num).toDouble() / 100
          : 0.0,
      penper: prefsMap['pen_per'] != null
          ? (prefsMap['pen_per'] as num).toDouble() / 100
          : 0.0,
    );
  }
}