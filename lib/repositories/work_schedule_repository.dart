import 'package:workcalendar2/models/company.dart';
import 'package:workcalendar2/models/work_schedule.dart';
import 'package:workcalendar2/services/database_helper.dart';

class WorkScheduleRepository {
  final dbHelper = DatabaseHelper();

  Future<List<WorkSchedule>> getSchedulesByMonth(DateTime month) async {
    final db = await dbHelper.database;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final String query = '''
      SELECT
        ws.id, ws.companyId, ws.startDate, ws.endDate, ws.regDate, ws.uptDate,
        c.id as c_id, c.name as c_name, c.color as c_color, 
        c.workingDays as c_workingDays, c.startTime as c_startTime, c.endTime as c_endTime, 
        c.paymentType as c_paymentType, c.paymentAmount as c_paymentAmount, 
        c.lunchStartTime as c_lunchStartTime, c.lunchEndTime as c_lunchEndTime,
        c.regDate as c_regDate, c.uptDate as c_uptDate
      FROM work_schedules ws
      LEFT JOIN companies c ON ws.companyId = c.id
      WHERE ws.startDate BETWEEN ? AND ?
      ORDER BY ws.startDate ASC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [
      firstDayOfMonth.toIso8601String(),
      lastDayOfMonth.toIso8601String(),
    ]);

    return maps.map((map) {
      Company? company;
      if (map['c_id'] != null) {
        // Create a temporary map for the company fields
        final companyMap = {
          'id': map['c_id'],
          'name': map['c_name'],
          'color': map['c_color'],
          'workingDays': map['c_workingDays'],
          'startTime': map['c_startTime'],
          'endTime': map['c_endTime'],
          'paymentType': map['c_paymentType'],
          'paymentAmount': map['c_paymentAmount'],
          'lunchStartTime': map['c_lunchStartTime'],
          'lunchEndTime': map['c_lunchEndTime'],
          'regDate': map['c_regDate'],
          'uptDate': map['c_uptDate'],
        };
        company = Company.fromMap(companyMap);
      }

      return WorkSchedule.fromMap(map).copyWith(company: company);
    }).toList();
  }

  Future<List<WorkSchedule>> getSchedulesByDay(DateTime day) async {
    final db = await dbHelper.database;
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

    final String query = '''
      SELECT
        ws.id, ws.companyId, ws.startDate, ws.endDate, ws.regDate, ws.uptDate,
        c.id as c_id, c.name as c_name, c.color as c_color, 
        c.workingDays as c_workingDays, c.startTime as c_startTime, c.endTime as c_endTime, 
        c.paymentType as c_paymentType, c.paymentAmount as c_paymentAmount, 
        c.lunchStartTime as c_lunchStartTime, c.lunchEndTime as c_lunchEndTime,
        c.regDate as c_regDate, c.uptDate as c_uptDate
      FROM work_schedules ws
      LEFT JOIN companies c ON ws.companyId = c.id
      WHERE ws.startDate BETWEEN ? AND ?
      ORDER BY ws.startDate ASC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [
      startOfDay.toIso8601String(),
      endOfDay.toIso8601String(),
    ]);

    return maps.map((map) {
      Company? company;
      if (map['c_id'] != null) {
        final companyMap = {
          'id': map['c_id'],
          'name': map['c_name'],
          'color': map['c_color'],
          'workingDays': map['c_workingDays'],
          'startTime': map['c_startTime'],
          'endTime': map['c_endTime'],
          'paymentType': map['c_paymentType'],
          'paymentAmount': map['c_paymentAmount'],
          'lunchStartTime': map['c_lunchStartTime'],
          'lunchEndTime': map['c_lunchEndTime'],
          'regDate': map['c_regDate'],
          'uptDate': map['c_uptDate'],
        };
        company = Company.fromMap(companyMap);
      }

      return WorkSchedule.fromMap(map).copyWith(company: company);
    }).toList();
  }

  Future<List<WorkSchedule>> getSchedulesByDateRange(DateTime start, DateTime end) async {
    final db = await dbHelper.database;
    final String query = '''
      SELECT
        ws.id, ws.companyId, ws.startDate, ws.endDate, ws.regDate, ws.uptDate,
        c.id as c_id, c.name as c_name, c.color as c_color, 
        c.workingDays as c_workingDays, c.startTime as c_startTime, c.endTime as c_endTime, 
        c.paymentType as c_paymentType, c.paymentAmount as c_paymentAmount, 
        c.lunchStartTime as c_lunchStartTime, c.lunchEndTime as c_lunchEndTime,
        c.regDate as c_regDate, c.uptDate as c_uptDate
      FROM work_schedules ws
      LEFT JOIN companies c ON ws.companyId = c.id
      WHERE ws.startDate >= ? AND ws.startDate <= ?
      ORDER BY ws.startDate ASC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [
      start.toIso8601String(),
      end.toIso8601String(),
    ]);

    return maps.map((map) {
      Company? company;
      if (map['c_id'] != null) {
        final companyMap = {
          'id': map['c_id'],
          'name': map['c_name'],
          'color': map['c_color'],
          'workingDays': map['c_workingDays'],
          'startTime': map['c_startTime'],
          'endTime': map['c_endTime'],
          'paymentType': map['c_paymentType'],
          'paymentAmount': map['c_paymentAmount'],
          'lunchStartTime': map['c_lunchStartTime'],
          'lunchEndTime': map['c_lunchEndTime'],
          'regDate': map['c_regDate'],
          'uptDate': map['c_uptDate'],
        };
        company = Company.fromMap(companyMap);
      }

      return WorkSchedule.fromMap(map).copyWith(company: company);
    }).toList();
  }

  Future<int> addWorkSchedule(WorkSchedule schedule) async {
    final db = await dbHelper.database;
    return await db.insert('work_schedules', schedule.toMap());
  }

  Future<int> updateWorkSchedule(WorkSchedule schedule) async {
    final db = await dbHelper.database;
    return await db.update(
      'work_schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteWorkSchedule(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'work_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCompanyForSchedulesInRange(int companyId, DateTime start, DateTime end) async {
    final db = await dbHelper.database;
    return await db.update(
      'work_schedules',
      {'companyId': companyId},
      where: 'companyId IS NULL AND startDate >= ? AND startDate <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
  }
} 