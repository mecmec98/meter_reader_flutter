import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class ClusterdatabaseHelper {
  static final ClusterdatabaseHelper _instance =
      ClusterdatabaseHelper._internal();
  factory ClusterdatabaseHelper() => _instance;

  final String _dbName = 'clusterdatabase.db';
  static Database? _database;

  ClusterdatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> getDatabasePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _dbName);
  }

  Future<Database> _initDatabase() async {
    String path = await getDatabasePath();
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS clusters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cluter TEXT NOT NULL,
            acc_num TEXT UNIQUE NOT NULL
            acc_name TEXT NOT NULL,
            acc_meternum TEXT NOT NULL
          )
        ''');
      },
    );
  }

//insert data into the clusters table
  Future<int> insertCluster(String cluster, String accNum) async {
    try {
      //check if acc_num already exists
      final existingId = await getClusterIdByAccNum(accNum);
      final db = await database;
      if (existingId != null) {
        // If acc_num exists, update the cluster instead of inserting
        return await updateClusterByAccNum(cluster, accNum);
      }
      return await db
          .insert('clusters', {'cluter': cluster, 'acc_num': accNum});
      //successfully inserted
    } catch (e) {
      print('Error in insertCluster: $e');
      return -1; // or throw, or handle as you wish
    }
  }

//get all clusters
  Future<List<Map<String, dynamic>>> getAllClusters() async {
    try {
      final db = await database;
      return await db.query('clusters');
    } catch (e) {
      print('Error in getAllClusters: $e');
      return [];
    }
  }

//get cluster id by acc_num
  Future<int?> getClusterIdByAccNum(String accNum) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'clusters',
        where: 'acc_num = ?',
        whereArgs: [accNum],
      );
      if (result.isNotEmpty) {
        return result.first['id'] as int?;
      }
      return null;
    } catch (e) {
      print('Error in getClusterIdByAccNum: $e');
      return null;
    }
  }

//update cluster by acc_num
  Future<int> updateClusterByAccNum(String cluster, String accNum) async {
    try {
      final db = await database;
      return await db.update(
        'clusters',
        {'cluter': cluster},
        where: 'acc_num = ?',
        whereArgs: [accNum],
      );
    } catch (e) {
      print('Error in updateClusterByAccNum: $e');
      return -1; // or throw, or handle as you wish
    }
  }

}
