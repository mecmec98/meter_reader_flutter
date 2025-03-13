import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(SampleSpace());
}

class SampleSpace extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DatabaseManagementScreen(),
    );
  }
}

class DatabaseManagementScreen extends StatefulWidget {
  @override
  DatabaseManagementScreenState createState() => DatabaseManagementScreenState();
}

class DatabaseManagementScreenState extends State<DatabaseManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    List<Map<String, dynamic>> data = await _dbHelper.queryAll();
    setState(() => _data = data);
  }

  Future<void> _importDatabase() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null) {
      bool success = await _dbHelper.importNewDatabase(result.files.single.path!);
      if (success) {
        await _loadData();
        print('database succesful');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Database Manager')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _importDatabase,
            child: Text('Replace Database'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _data.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_data[index]['cutdate'] ?? ''),
                  subtitle: Text('ID: ${_data[index]['_id']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  final String _dbName = 'my_database.db';
  

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);

    // Check if database exists
    bool exists = await databaseExists(path);

    if (!exists) {
      // Copy from assets if not exists
      await _copyDatabaseFromAssets(path);
    }

    return await openDatabase(path);
  }

  Future<void> _copyDatabaseFromAssets(String path) async {
    // Create parent directories if needed
    await Directory(dirname(path)).create(recursive: true);
    
    // Copy from assets (your initial database should be in assets folder)
    // For this example, we'll create a new empty database
    Database database = await openDatabase(path);
    await database.execute('''
      CREATE TABLE prefs (
        id INTEGER PRIMARY KEY,
        name TEXT
      )
    ''');

    await database.close();
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

  Future<List<Map<String, dynamic>>> queryAll() async {
    Database db = await instance.database;
    return await db.query('prefs');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}