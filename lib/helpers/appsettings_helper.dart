import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:meter_reader_flutter/models/features_model.dart';
import 'package:meter_reader_flutter/models/databaselog_model.dart';
import 'package:meter_reader_flutter/models/serversettings_model.dart';

class AppSettingsHelper {
  static final AppSettingsHelper _instance = AppSettingsHelper._internal();
  factory AppSettingsHelper() => _instance;
  AppSettingsHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_settings.db');

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Auto-clean logs older than 1 year on every init
    await _clearOldLogs(db);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Features table
    await db.execute('''
      CREATE TABLE features (
        key TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Seed default features
    await db.insert('features', {
      'key': 'feature_placeholder_1',
      'label': 'Placeholder Feature 1',
      'enabled': 1,
    });
    await db.insert('features', {
      'key': 'feature_placeholder_2',
      'label': 'Placeholder Feature 2',
      'enabled': 1,
    });

    // Logs table
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        method TEXT NOT NULL,
        datetime TEXT NOT NULL
      )
    ''');

    //Server settings table
    await db.execute('''
      CREATE TABLE server_settings (
        id INTEGER PRIMARY KEY,
        server_ip TEXT NOT NULL DEFAULT '',
        server_port INTEGER NOT NULL DEFAULT 8765
      )
    ''');

    // Seed default row
    await db.insert('server_settings', {
      'id': 1,
      'server_ip': '192.168.1.188',
      'server_port': 8765,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add logs table for existing installs that only have features table
      await db.execute('''
        CREATE TABLE logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          method TEXT NOT NULL,
          datetime TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
    CREATE TABLE server_settings (
      id INTEGER PRIMARY KEY,
      server_ip TEXT NOT NULL DEFAULT '',
      server_port INTEGER NOT NULL DEFAULT 8765
    )
  ''');
      await db.insert('server_settings', {
        'id': 1,
        'server_ip': '192.168.1.188',
        'server_port': 8765,
      });
    }
  }

  Future<void> _clearOldLogs(Database db) async {
    final cutoff =
        DateTime.now().subtract(const Duration(days: 365)).toIso8601String();
    await db.delete(
      'logs',
      where: 'datetime < ?',
      whereArgs: [cutoff],
    );
  }

  // ─────────────────────────────────────────
  // Features
  // ─────────────────────────────────────────

  /// Get all features
  Future<List<FeatureModel>> getAllFeatures() async {
    final db = await database;
    final rows = await db.query('features');
    return rows.map((row) => FeatureModel.fromMap(row)).toList();
  }

  /// Get a single feature by key
  Future<FeatureModel?> getFeature(String key) async {
    final db = await database;
    final rows = await db.query(
      'features',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return FeatureModel.fromMap(rows.first);
  }

  /// Check if a feature is enabled
  Future<bool> isEnabled(String key) async {
    final feature = await getFeature(key);
    return feature?.enabled ?? false;
  }

  /// Toggle a feature on or off
  Future<void> setFeature(String key, bool enabled) async {
    final db = await database;
    await db.update(
      'features',
      {'enabled': enabled ? 1 : 0},
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  // ─────────────────────────────────────────
  // Logs
  // ─────────────────────────────────────────

  /// Add a new log entry
  /// [type] → 'upload' or 'download'
  /// [method] → 'wireless' or 'manual'
  Future<void> addLog({
    required String type,
    required String method,
  }) async {
    final db = await database;
    await db.insert('logs', {
      'type': type,
      'method': method,
      'datetime': DateTime.now().toIso8601String(),
    });
  }

  /// Get all logs ordered by most recent
  Future<List<DatabaseLogModel>> getLogs() async {
    final db = await database;
    final rows = await db.query('logs', orderBy: 'datetime DESC');
    return rows.map((row) => DatabaseLogModel.fromMap(row)).toList();
  }

  /// Get latest log for a specific type and method
  /// e.g. getLatestLog('upload', 'wireless')
  Future<DatabaseLogModel?> getLatestLog(String type, String method) async {
    final db = await database;
    final rows = await db.query(
      'logs',
      where: 'type = ? AND method = ?',
      whereArgs: [type, method],
      orderBy: 'datetime DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DatabaseLogModel.fromMap(rows.first);
  }

  /// Get latest logs for all 4 combinations at once
  Future<Map<String, DatabaseLogModel?>> getLatestLogs() async {
    final db = await database;

    Future<DatabaseLogModel?> fetch(String type, String method) async {
      final rows = await db.query(
        'logs',
        where: 'type = ? AND method = ?',
        whereArgs: [type, method],
        orderBy: 'datetime DESC',
        limit: 1,
      );
      return rows.isNotEmpty ? DatabaseLogModel.fromMap(rows.first) : null;
    }

    return {
      'upload_wireless': await fetch('upload', 'wireless'),
      'download_wireless': await fetch('download', 'wireless'),
      'upload_manual': await fetch('upload', 'manual'),
      'download_manual': await fetch('download', 'manual'),
    };
  }

  Future<ServerSettingsModel> getServerSettings() async {
    final db = await database;
    final rows =
        await db.query('server_settings', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return ServerSettingsModel(ip: '', port: 8765);
    return ServerSettingsModel.fromMap(rows.first);
  }

  Future<void> saveServerSettings(
      {required String ip, required int port}) async {
    final db = await database;
    await db.update(
      'server_settings',
      {'server_ip': ip, 'server_port': port},
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
