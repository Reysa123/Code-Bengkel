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
    await db.query('external_orders', where: 'id = ?', whereArgs: [id]).then((
      v,
    ) async {
      final type = v.first['type'];
      String tipe = '';
      if (type.toString().toLowerCase() == 'service') {
        tipe = 'opl';
      }
      if (type.toString().toLowerCase() == 'part') {
        tipe = 'opb';
      }
      await db.delete(
        "wo_items",
        where: 'type = ? AND item_id = ?',
        whereArgs: [tipe, id],
      );
    });
    return await db.delete('external_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ExternalOrder>> getByNoWo(int id) async {
    final db = await _db;
    final maps = await db.query(
      'external_orders',
      where: 'wo_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => ExternalOrder.fromMap(maps[i]));
  }

  Future<List<ExternalOrder>> getAll() async {
    final db = await _db;
    final result = await db.query('external_orders', orderBy: 'id DESC');
    return result.map((row) => ExternalOrder.fromMap(row)).toList();
  }
}
