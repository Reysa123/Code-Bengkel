// 2. lib/data/repositories/mechanic_repository.dart
import '../../core/database/database_helper.dart';
import '../models/mechanic.dart';

class MechanicRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Mechanic>> getAll() async {
    final db = await dbHelper.database;
    final maps = await db.query('mechanics', orderBy: 'nama ASC');
    return maps.map((e) => Mechanic.fromMap(e)).toList();
  }

  Future<int> insert(Mechanic mechanic) async {
    final db = await dbHelper.database;
    return await db.insert('mechanics', mechanic.toMap());
  }

  Future<int> update(Mechanic mechanic) async {
    final db = await dbHelper.database;
    return await db.update('mechanics', mechanic.toMap(), where: 'id = ?', whereArgs: [mechanic.id]);
  }

  Future<int> delete(int id) async {
    final db = await dbHelper.database;
    return await db.delete('mechanics', where: 'id = ?', whereArgs: [id]);
  }
}