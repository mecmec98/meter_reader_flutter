import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:meter_reader_flutter/models/consumer_note_model.dart';

class NotesHelper {
  static final NotesHelper _instance = NotesHelper._internal();
  factory NotesHelper() => _instance;
  NotesHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> getDatabasePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'MRANOTES.db');
  }

  Future<Database> _initDatabase() async {
    String path = await getDatabasePath();
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE consumer_notes (
            _id INTEGER PRIMARY KEY AUTOINCREMENT,
            mas_code INTEGER NOT NULL,
            note_text TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            reading_date TEXT NOT NULL,
            reader_name TEXT NOT NULL,
            zb TEXT NOT NULL,
            is_archived INTEGER NOT NULL DEFAULT 0,
            archived_at TEXT
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_notes_mas_code ON consumer_notes(mas_code)');
        await db.execute(
            'CREATE INDEX idx_notes_zb ON consumer_notes(zb)');
        await db.execute(
            'CREATE INDEX idx_notes_archived ON consumer_notes(is_archived)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // v1 → v2: no schema changes, just establishing versioning
        }
        if (oldVersion < 3) {
          // v2 → v3: recreate table with mas_code as INTEGER
          await db.execute('DROP INDEX IF EXISTS idx_notes_mas_code');
          await db.execute('DROP INDEX IF EXISTS idx_notes_zb');
          await db.execute('DROP INDEX IF EXISTS idx_notes_archived');
          await db.execute('ALTER TABLE consumer_notes RENAME TO consumer_notes_old');
          await db.execute('''
            CREATE TABLE consumer_notes (
              _id INTEGER PRIMARY KEY AUTOINCREMENT,
              mas_code INTEGER NOT NULL,
              note_text TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              reading_date TEXT NOT NULL,
              reader_name TEXT NOT NULL,
              zb TEXT NOT NULL,
              is_archived INTEGER NOT NULL DEFAULT 0,
              archived_at TEXT
            )
          ''');
          await db.execute('INSERT INTO consumer_notes SELECT * FROM consumer_notes_old');
          await db.execute('DROP TABLE consumer_notes_old');
          await db.execute('CREATE INDEX idx_notes_mas_code ON consumer_notes(mas_code)');
          await db.execute('CREATE INDEX idx_notes_zb ON consumer_notes(zb)');
          await db.execute('CREATE INDEX idx_notes_archived ON consumer_notes(is_archived)');
        }
      },
    );
  }

  Future<int> insertNote(ConsumerNoteModel note) async {
    final db = await database;
    return await db.insert('consumer_notes', note.toMap());
  }

  Future<ConsumerNoteModel?> getLatestActiveNote(int masCode) async {
    final db = await database;
    final rows = await db.query(
      'consumer_notes',
      where: 'mas_code = ? AND is_archived = 0',
      whereArgs: [masCode],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ConsumerNoteModel.fromMap(rows.first);
  }

  Future<List<ConsumerNoteModel>> getAllNotes(int masCode) async {
    final db = await database;
    final rows = await db.query(
      'consumer_notes',
      where: 'mas_code = ?',
      whereArgs: [masCode],
      orderBy: 'created_at DESC',
    );
    return rows.map((row) => ConsumerNoteModel.fromMap(row)).toList();
  }

  Future<int> updateNote(int id, String newText) async {
    final db = await database;
    return await db.update(
      'consumer_notes',
      {
        'note_text': newText,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: '_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'consumer_notes',
      where: '_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> archiveAllActiveNotes() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'consumer_notes',
      {
        'is_archived': 1,
        'archived_at': now,
      },
      where: 'is_archived = 0',
    );
  }

  Future<int> getActiveNoteCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM consumer_notes WHERE is_archived = 0');
    return result.first['count'] as int;
  }

  Future<List<Map<String, dynamic>>> getNoteSummaries() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT mas_code, COUNT(*) as note_count
      FROM consumer_notes
      WHERE is_archived = 0
      GROUP BY mas_code
      ORDER BY MAX(created_at) DESC
    ''');
  }
}
