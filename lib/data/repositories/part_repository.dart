// 4. lib/data/repositories/part_repository.dart
import '../../core/database/database_helper.dart';
import '../models/part.dart';

class PartRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Part>> getAll() async {
    final db = await dbHelper.database;
    final maps = await db.query('parts', orderBy: 'nama ASC');
    return maps.map((e) => Part.fromMap(e)).toList();
  }

  Future<int> insert(Part part) async {
    final db = await dbHelper.database;
    return await db.insert('parts', part.toMap());
  }

  Future<int> update(Part part) async {
    final db = await dbHelper.database;
    return await db.update('parts', part.toMap(), where: 'id = ?', whereArgs: [part.id]);
  }

  Future<void> updateStok(int partId, int qtyChange) async {
    final db = await dbHelper.database;
    await db.rawUpdate('UPDATE parts SET stok = stok + ? WHERE id = ?', [qtyChange, partId]);
  }

  Future<int> delete(int id) async {
    final db = await dbHelper.database;
    return await db.delete('parts', where: 'id = ?', whereArgs: [id]);
  }
}