import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  Future<Database> _initDatabase() async {
    // On Linux in debug mode, initialize the ffi database factory.
    if (Platform.isLinux && kDebugMode) {
      print("Debug mode on Linux detected. Initializing sqflite ffi.");
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print("Using an in-memory database on Linux.");
      return await openDatabase(':memory:');
    }

    String dbPath = join(await getDatabasesPath(), 'MRADB.dbi');

    bool exist = await databaseExists(dbPath);

    if (!exist) {
      try {
        await Directory(dirname(dbPath)).create(recursive: true);
        ByteData data = await rootBundle.load('assets/database/MRADB.dbi');
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(dbPath).writeAsBytes(bytes, flush: true);
      } catch (e) {
        print('Error copying database: $e');
      }
    }
    return await openDatabase(dbPath);
  }

  Future<Map<String, dynamic>?> getMasterByID(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
      columns: ['ACC1', 'ADDRESS', 'NAME'],
      where: '_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getMasterByIDforlist(
      {int limit = 8, int offset = 0}) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
      columns: ['NAME', 'ADDRESS', 'MNO', '_id'],
      limit: limit,
      offset: offset,
    );
    return result;
  }

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
      ],
      where: '_id=?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getClassfromRates(int classcode) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'rates',
      columns: ['LTYPE'],
      where: 'code=?',
      whereArgs: [classcode],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }
}
