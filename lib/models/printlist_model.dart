import 'package:meter_reader_flutter/helpers/database_helper.dart';

class PrintlistModel {
  String printName;
  String printAddress;
  String printMeterno;
  int printID;

  PrintlistModel({
    required this.printName,
    required this.printAddress,
    required this.printMeterno,
    required this.printID,
  });

  factory PrintlistModel.fromMap(Map<String, dynamic> map) {
    return PrintlistModel(
      printName: map['NAME'],
      printAddress: map['ADDRESS'],
      printMeterno: map['MNO'],
      printID: map['_id'],
    );
  }
  // Static method to fetch a paginated list of models
  static Future<List<PrintlistModel>> getMasterByIDforPrintedlist(
      {int limit = 8, int offset = 0}) async {
    final dbHelper = DatabaseHelper();
    final List<Map<String, dynamic>> maps =
        await dbHelper.getMasterByIDforPrintedlist(limit: limit, offset: offset);
    return maps.map((map) => PrintlistModel.fromMap(map)).toList();
  }
}
