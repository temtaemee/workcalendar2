import 'package:workcalendar2/models/company.dart';
import 'package:workcalendar2/services/database_helper.dart';

class CompanyRepository {
  final dbHelper = DatabaseHelper();

  Future<int> addCompany(Company company) async {
    final db = await dbHelper.database;
    return await db.insert('companies', company.toMap());
  }

  Future<Company?> getCompany(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'companies',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Company.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Company>> getAllCompanies() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('companies');
    return List.generate(maps.length, (i) {
      return Company.fromMap(maps[i]);
    });
  }

  Future<int> updateCompany(Company company) async {
    final db = await dbHelper.database;
    return await db.update(
      'companies',
      company.toMap(),
      where: 'id = ?',
      whereArgs: [company.id],
    );
  }

  Future<int> deleteCompany(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'companies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 