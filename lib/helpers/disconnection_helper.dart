import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:meter_reader_flutter/models/disconnection_model.dart';

class DisconnectionHelper {
  static final DisconnectionHelper _instance = DisconnectionHelper._internal();
  factory DisconnectionHelper() => _instance;
  DisconnectionHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> getDatabasePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'disconnections.db');
  }

  Future<Database> _initDatabase() async {
    String path = await getDatabasePath();
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE disconnections (
            _id INTEGER PRIMARY KEY AUTOINCREMENT,
            acc_no TEXT NOT NULL,
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            met_no TEXT NOT NULL,
            brand TEXT NOT NULL,
            lrdg INTEGER NOT NULL,
            months INTEGER NOT NULL,
            oldest TEXT NOT NULL,
            balance REAL NOT NULL,
            others TEXT,
            pay_date TEXT,
            pay_amt REAL NOT NULL,
            months2 INTEGER,
            oldest1 TEXT,
            mas_code INTEGER NOT NULL,
            met_stat TEXT NOT NULL,
            discon_reading INTEGER NOT NULL,
            remarks TEXT NOT NULL,
            discon_date TEXT NOT NULL,
            option_type TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE UNIQUE INDEX idx_discon_acc_no ON disconnections(acc_no)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // future migrations here
      },
    );
  }

  Future<int> insertDisconnection(DisconnectionModel item) async {
    final db = await database;
    return await db.insert('disconnections', item.toMap());
  }

  Future<int> updateDisconnectionDetails(DisconnectionModel item) async {
    final db = await database;
    return await db.update(
      'disconnections',
      {
        'discon_reading': item.disconReading,
        'met_stat': item.metStat,
        'remarks': item.remarks,
      },
      where: 'acc_no = ?',
      whereArgs: [item.accNo],
    );
  }

  Future<List<DisconnectionModel>> getAllDisconnections() async {
    final db = await database;
    final rows = await db.query('disconnections', orderBy: 'name ASC');
    return rows.map((row) => DisconnectionModel.fromMap(row)).toList();
  }

  Future<int> upsertDisconnections(List<DisconnectionModel> items) async {
    final db = await database;
    int count = 0;
    await db.transaction((txn) async {
      for (final item in items) {
        final updated = await txn.update(
          'disconnections',
          item.toMap(),
          where: 'acc_no = ?',
          whereArgs: [item.accNo],
        );
        if (updated == 0) {
          await txn.insert('disconnections', item.toMap());
        }
        count++;
      }
    });
    return count;
  }

  Future<int> clearDisconnections() async {
    final db = await database;
    return await db.delete('disconnections');
  }
}
