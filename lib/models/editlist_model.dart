import 'package:meter_reader_flutter/helpers/database_helper.dart';

class EditlistModel {
  String printName;
  String printAddress;
  String printMeterno;
  int printID;

  EditlistModel({
    required this.printName,
    required this.printAddress,
    required this.printMeterno,
    required this.printID,
  });

  factory EditlistModel.fromMap(Map<String, dynamic> map) {
    return EditlistModel(
      printName: map['NAME'] ?? '',
      printAddress: map['ADDRESS'] ?? '',
      printMeterno: map['MNO'] ?? '',
      printID: map['_id'] is int ? map['_id'] as int : 0,
    );
  }
  // Static method to fetch a paginated list of models
  static Future<List<EditlistModel>> getMasterByIDforEditlist(
      { int offset = 0}) async {
    final dbHelper = DatabaseHelper();
    final List<Map<String, dynamic>> maps =
        await dbHelper.getMasterByIDforPrintedlist(offset: offset);
    return maps.map((map) => EditlistModel.fromMap(map)).toList();
  }
}
