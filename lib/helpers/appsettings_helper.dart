import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:meter_reader_flutter/models/features_model.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
  }

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
}

