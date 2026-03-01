// 3. lib/data/repositories/service_repository.dart
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/service.dart';

class ServiceRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Service>> getAll() async {
    final db = await dbHelper.database;
    final maps = await db.query('services', orderBy: 'nama ASC');
    return maps.map((e) => Service.fromMap(e)).toList();
  }

  Future<int> insert(Service service) async {
    final db = await dbHelper.database;
    return await db.insert('services', service.toMap());
  }

  Future<int> update(Service service) async {
    final db = await dbHelper.database;
    return await db.update('services', service.toMap(), where: 'id = ?', whereArgs: [service.id]);
  }

  Future<int> delete(int id) async {
    final db = await dbHelper.database;
    return await db.delete('services', where: 'id = ?', whereArgs: [id]);
  }
}