import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:work_calendar_app/models/company.dart';
import 'package:work_calendar_app/models/work_record.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'work_calendar.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS work_records');
      await db.execute('DROP TABLE IF EXISTS companies');
      await _createTables(db);
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        workDays TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        excludeLunchTime INTEGER NOT NULL,
        lunchStartTime TEXT,
        lunchEndTime TEXT,
        hourlyWage REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE work_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        checkIn TEXT,
        checkOut TEXT,
        company_id INTEGER NOT NULL,
        hourlyWage REAL NOT NULL,
        FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE CASCADE
      )
    ''');
  }

  // Company CRUD operations
  Future<int> insertCompany(Company company) async {
    final db = await database;
    try {
      return await db.insert('companies', company.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error inserting company: $e');
      return -1;
    }
  }

  Future<List<Company>> getCompanies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('companies');
    return List.generate(maps.length, (i) {
      return Company.fromJson(maps[i]);
    });
  }

  Future<Company?> getCompanyById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'companies',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Company.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateCompany(Company company) async {
    final db = await database;
    return await db.update(
      'companies',
      company.toJson(),
      where: 'id = ?',
      whereArgs: [company.id],
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  Future<int> deleteCompany(int id) async {
    final db = await database;
    return await db.delete(
      'companies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // WorkRecord CRUD operations
  Future<int> insertWorkRecord(WorkRecord workRecord) async {
    final db = await database;
    try {
      return await db.insert('work_records', workRecord.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error inserting work_record: $e');
      return -1;
    }
  }

Future<List<WorkRecord>> getWorkRecords() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    'work_records',
    orderBy: 'date ASC',
  );
  return List.generate(maps.length, (i) {
    return WorkRecord.fromJson(maps[i]);
  });
}

  Future<List<WorkRecord>> getWorkRecordsByDate(DateTime date) async {
    final db = await database;
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final List<Map<String, dynamic>> maps = await db.query(
      'work_records',
      where: 'date = ?',
      whereArgs: [dateString],
    );
    return List.generate(maps.length, (i) {
      return WorkRecord.fromJson(maps[i]);
    });
  }

  Future<List<WorkRecord>> getWorkRecordsByCompanyAndDateRange(int companyId, DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateString = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateString = DateFormat('yyyy-MM-dd').format(endDate);
    final List<Map<String, dynamic>> maps = await db.query(
      'work_records',
      where: 'company_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [companyId, startDateString, endDateString],
      orderBy: 'date ASC',
    );
    return List.generate(maps.length, (i) {
      return WorkRecord.fromJson(maps[i]);
    });
  }

  Future<int> updateWorkRecord(WorkRecord workRecord) async {
    final db = await database;
    return await db.update(
      'work_records',
      workRecord.toJson(),
      where: 'id = ?',
      whereArgs: [workRecord.id],
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  Future<int> deleteWorkRecord(int id) async {
    final db = await database;
    return await db.delete(
      'work_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 근무 시간 및 급여 계산 (SQLite는 복잡한 시간 계산 함수가 제한적이므로, Dart에서 처리하는 것을 권장)
  // 여기서는 월별 총 근무 시간(분 단위)과 총 예상 급여를 가져오는 예시를 SQL로 작성합니다.
  // TimeOfDay 문자열("HH:mm")을 분으로 변환하는 것은 SQLite에서 직접 하기 까다롭습니다.
  // 따라서 checkIn, checkOut 시간을 초 단위로 저장하거나, 애플리케이션 레벨에서 계산하는 것이 일반적입니다.
  // 아래는 문자열을 그대로 두고, 각 레코드의 hourlyWage와 Duration을 가져와 Dart에서 계산한다고 가정합니다.

  // 월별 근무 기록 및 급여 집계
  Future<List<Map<String, dynamic>>> getMonthlyWorkSummary(int companyId, int year, int month) async {
    final db = await database;
    // SQLite는 JULIANDAY를 사용하여 날짜 간 차이를 계산할 수 있지만, HH:MM 형식의 시간 차이 계산은 복잡합니다.
    // checkIn, checkOut이 TEXT로 저장되어 있으므로, 각 레코드를 가져와 Dart에서 Duration을 계산하는 것이 더 효율적일 수 있습니다.
    // 여기서는 각 레코드의 데이터를 가져와서 Dart에서 처리할 수 있도록 합니다.

    final monthString = month.toString().padLeft(2, '0');
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        date,
        checkIn,
        checkOut,
        hourlyWage
      FROM work_records
      WHERE company_id = ? AND strftime('%Y-%m', date) = ?
      ORDER BY date ASC
    ''', [companyId, '$year-$monthString']);
    
    return result; // 이 결과를 바탕으로 Dart에서 각 레코드의 workDuration과 dailyWage를 계산하여 합산합니다.
  }

  // 특정 월의 총 근무 시간 (분) - Dart에서 계산하는 것을 권장
  // Future<int> getTotalWorkMinutesForMonth(int companyId, int year, int month) async { ... }
  
  // 특정 월의 총 예상 급여 - Dart에서 계산하는 것을 권장
  // Future<double> getTotalExpectedWageForMonth(int companyId, int year, int month) async { ... }

  // 데이터베이스 닫기 (앱 종료 시 호출)
  Future close() async {
    final db = await database;
    db.close();
    _database = null;
  }

  Future<List<WorkRecord>> getTodayWorkRecords() async {
    final today = DateTime.now();
    return await getWorkRecordsByDate(today);
  }

  Future<List<WorkRecord>> getWorkRecordsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateString = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateString = DateFormat('yyyy-MM-dd').format(endDate);
    final List<Map<String, dynamic>> maps = await db.query(
      'work_records',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDateString, endDateString],
      orderBy: 'date ASC',
    );
    print('[DB] getWorkRecordsByDateRange: $startDateString ~ $endDateString, count: \'${maps.length}\'');

    print(maps);
    return List.generate(maps.length, (i) {
      return WorkRecord.fromJson(maps[i]);
    });
  }
} 