import 'dart:io';
import 'package:path/path.dart';
// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;
  final String _dbName = 'MRADB.dbi';
  static const String _importBackupName = 'MRADB-backup-before-import.dbi';
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

  Future<String> getImportBackupPath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _importBackupName);
  }

  Future<void> _validateDatabaseFile(String path) async {
    final db = await openDatabase(path, readOnly: true);
    try {
      await _validateDatabase(db);
    } finally {
      await db.close();
    }
  }

  Future<void> _validateDatabase(Database db) async {
    final integrity = await db.rawQuery('PRAGMA quick_check');
    if (integrity.length != 1 ||
        integrity.first['quick_check'].toString().toLowerCase() != 'ok') {
      throw const FormatException('Database integrity check failed.');
    }

    const requiredColumns = <String, Set<String>>{
      'master': {
        '_id',
        'NAME',
        'ADDRESS',
        'MNO',
        'POSTED',
        'BILL_STAT',
        'CLSSSZ',
      },
      'prefs': {
        '_id',
        'cutdate',
        'datedue',
        'billdate',
        'meterreader',
        'ftaxbill',
        'pen_per',
      },
      'rates': {'_id', 'CODE', 'LTYPE'},
    };

    for (final entry in requiredColumns.entries) {
      final tables = await db.rawQuery(
        'SELECT name FROM sqlite_master WHERE type = ? AND lower(name) = ?',
        ['table', entry.key],
      );
      if (tables.isEmpty) {
        throw FormatException('Database is missing the ${entry.key} table.');
      }

      final columns = await db.rawQuery('PRAGMA table_info("${entry.key}")');
      final actualColumns = columns
          .map((column) => column['name'].toString().toLowerCase())
          .toSet();
      final missingColumns = entry.value
          .where((column) => !actualColumns.contains(column.toLowerCase()));
      if (missingColumns.isNotEmpty) {
        throw FormatException(
          'Database ${entry.key} table is missing required columns: '
          '${missingColumns.join(', ')}.',
        );
      }
    }

    final prefs = await db.query('prefs', limit: 1);
    final rates = await db.query('rates', limit: 1);
    final master = await db.query('master', limit: 1);
    if (prefs.isEmpty || rates.isEmpty || master.isEmpty) {
      throw const FormatException(
        'Database must contain consumer, preference, and rate records.',
      );
    }
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
    final sourceFile = File(sourcePath);
    final destPath = await getDatabasePath();
    final backupPath = await getImportBackupPath();
    final documentsDirectory = Directory(dirname(destPath));
    final importId = DateTime.now().microsecondsSinceEpoch;
    final stagedPath =
        join(documentsDirectory.path, 'MRADB-import-$importId.dbi');
    final backupStagedPath =
        join(documentsDirectory.path, 'MRADB-backup-$importId.tmp');
    var backupCreated = false;
    var hadLiveDatabase = false;

    try {
      if (!await sourceFile.exists()) {
        throw const FileSystemException(
            'Selected database file does not exist.');
      }
      if (normalize(sourceFile.absolute.path) == normalize(destPath)) {
        throw const FileSystemException(
          'The selected file is already the active database.',
        );
      }

      await sourceFile.copy(stagedPath);
      await _validateDatabaseFile(stagedPath);

      hadLiveDatabase = await File(destPath).exists();
      if (_database?.isOpen ?? false) {
        await _database!.close();
      }
      _database = null;

      if (hadLiveDatabase) {
        await File(destPath).copy(backupStagedPath);
        final backupFile = File(backupPath);
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        await File(backupStagedPath).rename(backupPath);
        backupCreated = true;

        await deleteDatabase(destPath);
      }

      await File(stagedPath).rename(destPath);
      _database = await _initDatabase();
      await _validateDatabase(_database!);
      return true;
    } catch (e) {
      print('Error replacing database: $e');

      try {
        if (_database?.isOpen ?? false) {
          await _database!.close();
        }
        _database = null;

        if (backupCreated) {
          await deleteDatabase(destPath);
          await File(backupPath).copy(destPath);
          _database = await _initDatabase();
          await _validateDatabase(_database!);
        } else if (await File(destPath).exists()) {
          _database = await _initDatabase();
        }
      } catch (rollbackError) {
        _database = null;
        throw StateError(
          'Database import failed and automatic rollback also failed. '
          'The recovery backup is at $backupPath. '
          'Import error: $e. Rollback error: $rollbackError',
        );
      }
      return false;
    } finally {
      for (final path in [stagedPath, backupStagedPath]) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

//for database export
  Future<bool> exportDatabase() async {
    try {
      // Get the database file path
      String sourcePath = await getDatabasePath();
      File sourceFile = File(sourcePath);

      //incrementing name for backup MRADB-backup(1 check if it exist then +1).dbi
      String backupFileName = 'MRADB-backup.dbi';
      int backupIndex = 1;
      while (await File(join('/storage/emulated/0/Download', backupFileName))
          .exists()) {
        backupFileName = 'MRADB-backup(${backupIndex++}).dbi';
      }

      // Get the Downloads directory path
      Directory downloadsDirectory = Directory('/storage/emulated/0/Download');
      String destPathbackup = join(downloadsDirectory.path, backupFileName);
      String destPath = join(downloadsDirectory.path, 'MRADB.dbo');

      // Copy 2 of the database file to the Downloads directory
      await sourceFile.copy(destPathbackup);
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
        orderBy: '_id ASC',
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
      where:
          '(NAME LIKE ? OR ADDRESS LIKE ? OR MNO LIKE ?) AND POSTED=? AND BILL_STAT=?',
      whereArgs: ['%$query%', '%$query%', '%$query%', 1, 1],
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
      {int offset = 0}) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
      columns: ['NAME', 'ADDRESS', 'MNO', '_id'],
      where: 'POSTED=?',
      whereArgs: [1],
      offset: offset,
    );
    return result;
  }

  //for getting data for the already Printed Bill List
  Future<List<Map<String, dynamic>>> getMasterByIDforPrintedlist(
      {int offset = 0}) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
      columns: ['NAME', 'ADDRESS', 'MNO', '_id'],
      where: 'POSTED=? AND BILL_STAT=?',
      whereArgs: [1, 2],
      offset: offset,
    );
    return result;
  }

  //for getting data for the saved only Printed Bill List
  Future<List<Map<String, dynamic>>> getMasterByIDforSavedlist(
      {int offset = 0}) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
      columns: ['NAME', 'ADDRESS', 'MNO', '_id'],
      where: 'POSTED=? AND BILL_STAT=?',
      whereArgs: [1, 1],
      offset: offset,
    );
    return result;
  }

//for populating the consumer data check consumercard_model.dart
  Future<Map<String, dynamic>?> getCardByID(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
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
    final prefsTable = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type = ? AND lower(name) = ?',
      ['table', 'prefs'],
    );
    if (prefsTable.isEmpty) return null;

    List<Map<String, dynamic>> result = await db.query(
      'prefs',
      where: '_id=?',
      whereArgs: [1],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, int>> getReadingStats() async {
    final db = await database;
    final masterTable = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type = ? AND lower(name) = ?',
      ['table', 'master'],
    );
    if (masterTable.isEmpty) {
      return {'total': 0, 'completed': 0, 'remaining': 0};
    }

    final totalResult =
        await db.rawQuery('SELECT COUNT(*) as count FROM master');
    final postedResult = await db
        .rawQuery('SELECT COUNT(*) as count FROM master WHERE POSTED > 0');
    final total = totalResult.first['count'] as int;
    final completed = postedResult.first['count'] as int;
    return {
      'total': total,
      'completed': completed,
      'remaining': total - completed
    };
  }

//get all zone and books currently in database
  Future<List<String>> getDistinctZB() async {
    final db = await database;
    final masterTable = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type = ? AND lower(name) = ?',
      ['table', 'master'],
    );
    if (masterTable.isEmpty) return [];

    final result =
        await db.rawQuery('SELECT DISTINCT ZB FROM master ORDER BY ZB ASC');
    return result.map((row) => row['ZB'].toString()).toList();
  }

  Future<Map<String, dynamic>?> getConsumerByMasCode(int masCode) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'master',
      columns: ['NAME', 'ACC1', 'ZB', 'CLSSSZ'],
      where: 'MASCODE = ?',
      whereArgs: [masCode],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }
}
