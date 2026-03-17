import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/external_order.dart';

class ExternalOrderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await _dbHelper.database;

  Future<int> insert(ExternalOrder order) async {
    final db = await _db;
    return await db.insert('external_orders', order.toMap());
  }

  Future<int> update(ExternalOrder order) async {
    final db = await _db;
    return await db.update(
      'external_orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('external_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<ExternalOrder?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'external_orders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ExternalOrder.fromMap(maps.first);
  }

  Future<List<ExternalOrder>> getAll() async {
    final db = await _db;
    final result = await db.query('external_orders', orderBy: 'id DESC');
    return result.map((row) => ExternalOrder.fromMap(row)).toList();
  }
}
