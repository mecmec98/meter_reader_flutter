import 'dart:io';
import 'package:path/path.dart';
// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:share_plus/share_plus.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;
  final String _dbName = 'MRADB.dbi';
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

//getting the database path
  Future<String> getDatabasePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(
        documentsDirectory.path, _dbName); // Returns the full database path
  }

  Future<Database?> _initDatabase() async {
    print('Initiating Databse');
    try {
      if (_database != null && _database!.isOpen) {
        _database?.close();
      }

      String path = await getDatabasePath();

      bool exist = await databaseExists(path);
      if (!exist) {
        await Directory(dirname(path)).create(recursive: true);
      }
      return await openDatabase(path);
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to initialize the database: $e');
    }
  }

  Future<bool> importNewDatabase(String sourcePath) async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String destPath = join(documentsDirectory.path, _dbName);

      // Close existing database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Delete old database
      await deleteDatabase(destPath);

      // Copy new database
      File sourceFile = File(sourcePath);
      await sourceFile.copy(destPath);

      // Reinitialize database
      _database = await _initDatabase();
      return true;
    } catch (e) {
      print('Error replacing database: $e');
      return false;
    }
  }

//for database export
  Future<bool> exportDatabase() async {
     try {
      // Get the database file path
      String sourcePath = await getDatabasePath();
      File sourceFile = File(sourcePath);

      // Get the Downloads directory path
      Directory downloadsDirectory = Directory('/storage/emulated/0/Download');
      String destPath = join(downloadsDirectory.path, 'MRADB.dbo');

      // Copy the database file to the Downloads directory
      await sourceFile.copy(destPath);

      print('Database exported to $destPath');
      return true;
    } catch (e) {
      print(e);
      return false;
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
