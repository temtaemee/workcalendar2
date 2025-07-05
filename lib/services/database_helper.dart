import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'work_calendar.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE work_schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        companyId INTEGER,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        regDate TEXT NOT NULL,
        uptDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE companies(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        workingDays TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        paymentType TEXT,
        paymentAmount INTEGER,
        lunchStartTime TEXT,
        lunchEndTime TEXT,
        regDate TEXT NOT NULL,
        uptDate TEXT NOT NULL
      )
    ''');
  }
} 