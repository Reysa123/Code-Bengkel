// 7. lib/data/repositories/purchase_repository.dart
// (Model Purchase belum dikirim, saya sertakan di bawah)
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/purchase.dart';

class PurchaseRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Purchase>> getAll() async {
    final db = await dbHelper.database;
    final maps = await db.query('purchases', orderBy: 'tanggal DESC');
    return maps.map((e) => Purchase.fromMap(e)).toList();
  }

  Future<int> insert(Purchase purchase) async {
    final db = await dbHelper.database;
    return await db.insert('purchases', purchase.toMap());
  }

  Future<void> insertWithItems(Purchase purchase, List<PurchaseItem> items) async {
    final db = await dbHelper.database;
    final purchaseId = await insert(purchase);

    for (var item in items) {
      item.purchaseId = purchaseId;
      await db.insert('purchase_items', item.toMap());

      // Tambah stok part
      await db.rawUpdate(
        'UPDATE parts SET stok = stok + ? WHERE id = ?',
        [item.qty, item.partId],
      );
    }
  }
}