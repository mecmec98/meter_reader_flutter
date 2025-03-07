import 'package:meter_reader_flutter/helpers/database_helper.dart';

class PostmeterlistModel {
  String postName;
  String postAddress;
  String postMeterno;
  int postID;

  PostmeterlistModel({
    required this.postName,
    required this.postAddress,
    required this.postMeterno,
    required this.postID,
  });

  factory PostmeterlistModel.fromMap(Map<String, dynamic> map) {
    return PostmeterlistModel(
      postName: map['NAME'],
      postAddress: map['ADDRESS'],
      postMeterno: map['MNO'],
      postID: map['_id'],
    );
  }
  // Static method to fetch a paginated list of models
  static Future<List<PostmeterlistModel>?> getMasterModelList(
      {int limit = 8, int offset = 0}) async {
    try {
      final dbHelper = DatabaseHelper();
      final List<Map<String, dynamic>>? maps =
          await dbHelper.getMasterByIDforlist(limit: limit, offset: offset);
      return maps!.map((map) => PostmeterlistModel.fromMap(map)).toList();
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
