// 5. lib/data/repositories/supplier_repository.dart
// (Model Supplier belum dikirim, saya sertakan di bawah)
import '../../core/database/database_helper.dart';
import '../models/supplier.dart';   // ← buat file ini dulu

class SupplierRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Supplier>> getAll() async {
    final db = await dbHelper.database;
    final maps = await db.query('suppliers', orderBy: 'nama ASC');
    return maps.map((e) => Supplier.fromMap(e)).toList();
  }

  Future<int> insert(Supplier supplier) async {
    final db = await dbHelper.database;
    return await db.insert('suppliers', supplier.toMap());
  }

  Future<int> update(Supplier supplier) async {
    final db = await dbHelper.database;
    return await db.update('suppliers', supplier.toMap(), where: 'id = ?', whereArgs: [supplier.id]);
  }

  Future<int> delete(int id) async {
    final db = await dbHelper.database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }
}