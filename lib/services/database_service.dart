import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:schengen/models/stay_record.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'schengen_tracker.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stay_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_date INTEGER NOT NULL,
        exit_date INTEGER,
        notes TEXT
      )
    ''');
  }

  // Insert a stay record
  Future<int> insertStayRecord(StayRecord stayRecord) async {
    final db = await database;
    return await db.insert(
      'stay_records',
      stayRecord.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update a stay record
  Future<int> updateStayRecord(StayRecord stayRecord) async {
    final db = await database;
    return await db.update(
      'stay_records',
      stayRecord.toMap(),
      where: 'id = ?',
      whereArgs: [stayRecord.id],
    );
  }

  // Delete a stay record
  Future<int> deleteStayRecord(int id) async {
    final db = await database;
    return await db.delete('stay_records', where: 'id = ?', whereArgs: [id]);
  }

  // Get all stay records, sorted by entry date (newest first)
  Future<List<StayRecord>> getAllStayRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stay_records',
      orderBy: 'entry_date DESC',
    );

    return List.generate(maps.length, (i) {
      return StayRecord.fromMap(maps[i]);
    });
  }

  // Get a single stay record by ID
  Future<StayRecord?> getStayRecord(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stay_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return StayRecord.fromMap(maps.first);
    }
    return null;
  }
}
