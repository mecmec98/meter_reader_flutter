import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:meter_reader_flutter/models/disconnection_model.dart';

class DisconnectionReplacementResult {
  final int count;
  final String backupPath;

  const DisconnectionReplacementResult({
    required this.count,
    required this.backupPath,
  });
}

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
      version: 2,
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
            oldest TEXT,
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
        await db.execute(
            'CREATE UNIQUE INDEX idx_discon_acc_no ON disconnections(acc_no)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE disconnections_new (
              _id INTEGER PRIMARY KEY AUTOINCREMENT,
              acc_no TEXT NOT NULL,
              name TEXT NOT NULL,
              address TEXT NOT NULL,
              met_no TEXT NOT NULL,
              brand TEXT NOT NULL,
              lrdg INTEGER NOT NULL,
              months INTEGER NOT NULL,
              oldest TEXT,
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
          await db.execute('''
            INSERT INTO disconnections_new (
              _id, acc_no, name, address, met_no, brand, lrdg, months,
              oldest, balance, others, pay_date, pay_amt, months2, oldest1,
              mas_code, met_stat, discon_reading, remarks, discon_date, option_type
            )
            SELECT
              _id, acc_no, name, address, met_no, brand, lrdg, months,
              oldest, balance, others, pay_date, pay_amt, months2, oldest1,
              mas_code, met_stat, discon_reading, remarks, discon_date, option_type
            FROM disconnections
          ''');
          await db.execute('DROP TABLE disconnections');
          await db.execute(
            'ALTER TABLE disconnections_new RENAME TO disconnections',
          );
          await db.execute(
            'CREATE UNIQUE INDEX idx_discon_acc_no ON disconnections(acc_no)',
          );
        }
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

  Future<String> exportDisconnections() async {
    final items = await getAllDisconnections();
    final fileName = 'DISCONNECTED_ACCOUNTS.json';
    final downloadsDirectory = Directory('/storage/emulated/0/Download');

    await downloadsDirectory.create(recursive: true);
    final file = File(join(downloadsDirectory.path, fileName));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        items.map((item) => item.toJsonMap()).toList(),
      ),
    );
    return file.path;
  }

  Future<DisconnectionReplacementResult> replaceDisconnections(
    List<DisconnectionModel> items,
  ) async {
    final backupPath = await createBackup();
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('disconnections');
      for (final item in items) {
        await txn.insert('disconnections', item.toMap());
      }
    });

    return DisconnectionReplacementResult(
      count: items.length,
      backupPath: backupPath,
    );
  }

  Future<String> createBackup() async {
    final items = await getAllDisconnections();
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    final fileName = 'disconnect-data-$date.json';
    final downloadsDirectory = Directory('/storage/emulated/0/Download');

    await downloadsDirectory.create(recursive: true);
    final file = File(join(downloadsDirectory.path, fileName));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        items.map((item) => item.toJsonMap()).toList(),
      ),
    );
    return file.path;
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
