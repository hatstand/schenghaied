import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:schengen/models/stay_record.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text_patterns.dart';

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
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Get all existing records
      final List<Map<String, dynamic>> records = await db.query('stay_records');

      // Rename the old table
      await db.execute('ALTER TABLE stay_records RENAME TO stay_records_old');

      // Create the new table with TEXT date columns
      await db.execute('''
        CREATE TABLE stay_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entry_date TEXT NOT NULL,
          exit_date TEXT,
          notes TEXT
        )
      ''');

      // Migrate data with date conversion
      for (var record in records) {
        final entryDate = DateTime.fromMillisecondsSinceEpoch(
          record['entry_date'],
        );
        final exitDate = record['exit_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(record['exit_date'])
            : null;

        // Convert to LocalDate and then to ISO string format
        final localEntryDate = LocalDate.dateTime(entryDate);
        final localExitDate = exitDate != null
            ? LocalDate.dateTime(exitDate)
            : null;

        await db.insert('stay_records', {
          'id': record['id'],
          'entry_date': LocalDatePattern.iso.format(localEntryDate),
          'exit_date': localExitDate != null
              ? LocalDatePattern.iso.format(localExitDate)
              : null,
          'notes': record['notes'],
        });
      }

      // Drop the old table
      await db.execute('DROP TABLE stay_records_old');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stay_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_date TEXT NOT NULL,
        exit_date TEXT,
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
    // Using ORDER BY with the LocalDate string format (YYYY-MM-DD)
    // This works because ISO date string format sorts correctly
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
