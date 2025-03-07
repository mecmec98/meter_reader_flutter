import 'dart:io';
//import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:path/path.dart';
// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }



  Future<Database?> _initDatabase() async {

    if (Platform.isAndroid){
      print(Platform);
      await Permission.storage.request();
    }
    print('Initiating Databse');
    // On Linux in debug mode, initialize the ffi database factory.
    // if (Platform.isLinux && kDebugMode) {
    //   print("Debug mode on Linux detected. Initializing sqflite ffi.");
    //   sqfliteFfiInit();
    //   databaseFactory = databaseFactoryFfi;
    //   print("Using an in-memory database on Linux.");
    //   return await openDatabase(':memory:');
    // }
    try {
      List<Directory>? downloadsDir = await getExternalStorageDirectories(type: StorageDirectory.downloads);
      print('Downloads Directory $downloadsDir');
      if (downloadsDir == null) {
        throw Exception('Downloads directory not found');
      }
      //String dbPath = join(await getDatabasesPath(), 'MRADB.dbi');
      final dbPath = join((downloadsDir as Directory).path, 'MRADB.dbi');
      // if (!await Directory(downloadsDir.path).exists()){
      //   await Directory(downloadsDir.path).create(recursive: true);
      // }
      return await openDatabase(dbPath);
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null; // Optionally set it to null after closing
    }
  }

//used for testing
  Future<Map<String, dynamic>?> getMasterByID(int id) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> result = await db.query(
        'master',
        columns: ['ACC1', 'ADDRESS', 'NAME'],
        where: '_id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error $e');
      return null;
    }
  }

//for getting data for the Post Meter List
  Future<List<Map<String, dynamic>>?> getMasterByIDforlist(
      {int limit = 8, int offset = 0}) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> result = await db.query(
        'master',
        columns: ['NAME', 'ADDRESS', 'MNO', '_id'],
        where: 'POSTED=?',
        whereArgs: [0],
        limit: limit,
        offset: offset,
      );
      return result;
    } catch (e) {
      print('Erro $e');
      return null;
    }
  }

//for search function on Post Meter List
  Future<List<Map<String, dynamic>>> searchMasterData(String query) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
      columns: ['NAME', 'ADDRESS', 'MNO', '_id'],
      where: '(NAME LIKE ? OR ADDRESS LIKE ? OR MNO LIKE ?) AND POSTED=?',
      whereArgs: ['%$query%', '%$query%', '%$query%', 0],
    );
    return result;
  }

//for search function on Print List
  Future<List<Map<String, dynamic>>> searchPostedMasterData(
      String query) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
      columns: ['NAME', 'ADDRESS', 'MNO', '_id'],
      where: '(NAME LIKE ? OR ADDRESS LIKE ? OR MNO LIKE ?) AND POSTED=?',
      whereArgs: ['%$query%', '%$query%', '%$query%', 1],
    );
    return result;
  }

  //for search function on Print List
  Future<List<Map<String, dynamic>>> searchPrintedMasterData(
      String query) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
      columns: ['NAME', 'ADDRESS', 'MNO', '_id'],
      where:
          '(NAME LIKE ? OR ADDRESS LIKE ? OR MNO LIKE ?) AND POSTED=? AND BILL_STAT=?',
      whereArgs: ['%$query%', '%$query%', '%$query%', 1, 2],
    );
    return result;
  }

//for getting data for the Print Bill List
  Future<List<Map<String, dynamic>>> getMasterByIDforPrintlist(
      {int limit = 8, int offset = 0}) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
      columns: ['NAME', 'ADDRESS', 'MNO', '_id'],
      where: 'POSTED=?',
      whereArgs: [1],
      limit: limit,
      offset: offset,
    );
    return result;
  }

  //for getting data for the already Printed Bill List
  Future<List<Map<String, dynamic>>> getMasterByIDforPrintedlist(
      {int limit = 8, int offset = 0}) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
      columns: ['NAME', 'ADDRESS', 'MNO', '_id'],
      where: 'POSTED=? AND BILL_STAT=?',
      whereArgs: [1, 2],
      limit: limit,
      offset: offset,
    );
    return result;
  }

//for populating the consumer data check consumercard_model.dart
  Future<Map<String, dynamic>?> getCardByID(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
      columns: [
        'NAME',
        'ADDRESS',
        'MNO',
        '_id',
        'ACC1',
        'ZB',
        'CLSSSZ',
        'BRAND',
        'PREADING',
        'CREADING',
        'ARREARS',
        'ARO',
        'WMF',
        'AVE',
        'USAGE',
        'AMOUNT',
        'SCDISC',
        'WITHSCDISC',
      ],
      where: '_id=?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

//getter for rates
  Future<Map<String, dynamic>?> getClassfromRates(int classcode) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'rates',
      where: 'code=?',
      whereArgs: [classcode],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

//update for the master list
  Future<int> updateMasterData(int id, Map<String, dynamic> updatedData) async {
    //print('hi I updated');
    final db = await database;
    return await db.update(
      'master',
      updatedData,
      where: '_id = ?',
      whereArgs: [id],
    );
  }

  //get data from prefs
  Future<Map<String, dynamic>?> getPrefsData() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'prefs',
      where: '_id=?',
      whereArgs: [1],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }
}
