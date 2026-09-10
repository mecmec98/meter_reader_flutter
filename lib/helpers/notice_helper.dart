import 'dart:io';

import 'package:meter_reader_flutter/models/notice_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class NoticeHelper {
  static final NoticeHelper _instance = NoticeHelper._internal();
  factory NoticeHelper() => _instance;
  NoticeHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'notices.db');
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasePath();
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notices (
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
        await db.execute('CREATE UNIQUE INDEX idx_notice_acc_no ON notices(acc_no)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {},
    );
  }

  Future<int> insertNotice(NoticeModel item) async {
    final db = await database;
    return db.insert('notices', item.toMap());
  }

  Future<int> updateNoticeDetails(NoticeModel item) async {
    final db = await database;
    return db.update(
      'notices',
      {
        'discon_reading': item.disconReading,
        'met_stat': item.metStat,
        'remarks': item.remarks,
      },
      where: 'acc_no = ?',
      whereArgs: [item.accNo],
    );
  }

  Future<List<NoticeModel>> getAllNotices() async {
    final db = await database;
    final rows = await db.query('notices', orderBy: 'name ASC');
    return rows.map((row) => NoticeModel.fromMap(row)).toList();
  }

  Future<int> upsertNotices(List<NoticeModel> items) async {
    final db = await database;
    var count = 0;
    await db.transaction((txn) async {
      for (final item in items) {
        final updated = await txn.update(
          'notices',
          item.toMap(),
          where: 'acc_no = ?',
          whereArgs: [item.accNo],
        );
        if (updated == 0) {
          await txn.insert('notices', item.toMap());
        }
        count++;
      }
    });
    return count;
  }

  Future<int> clearNotices() async {
    final db = await database;
    return db.delete('notices');
  }
}