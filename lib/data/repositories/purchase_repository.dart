import '../../core/database/database_helper.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';

class PurchaseRepository {
  final dbHelper = DatabaseHelper.instance;

  // Simpan pembelian + semua item sekaligus (dalam transaksi)
  Future<int> createPurchaseWithItems(Purchase purchase, List<PurchaseItem> items) async {
    final db = await dbHelper.database;
    int purchaseId = 0;

    await db.transaction((txn) async {
      // 1. Insert purchase utama → dapatkan ID
      purchaseId = await txn.insert('purchases', purchase.toMap());

      // 2. Insert semua item, set purchase_id
      for (var item in items) {
        final itemMap = item.toMap()..['purchase_id'] = purchaseId;
        await txn.insert('purchase_items', itemMap);
      }
    });

    return purchaseId;
  }

  // Update stok part otomatis setelah pembelian selesai
  Future<void> updatePartStock(int partId, int qtyToAdd) async {
    final db = await dbHelper.database;
    await db.rawUpdate(
      'UPDATE parts SET stok = stok + ? WHERE id = ?',
      [qtyToAdd, partId],
    );
  }

  // Ambil semua pembelian (untuk list/history)
  Future<List<Purchase>> getAllPurchases() async {
    final db = await dbHelper.database;
    final maps = await db.query('purchases', orderBy: 'tanggal DESC');
    return maps.map((m) => Purchase.fromMap(m)).toList();
  }

  // Ambil detail item dari satu pembelian
  Future<List<PurchaseItem>> getItemsByPurchaseId(int purchaseId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    return maps.map((m) => PurchaseItem.fromMap(m)).toList();
  }

  // Optional: hapus pembelian + item terkait
  Future<void> deletePurchase(int purchaseId) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('purchase_items', where: 'purchase_id = ?', whereArgs: [purchaseId]);
      await txn.delete('purchases', where: 'id = ?', whereArgs: [purchaseId]);
    });
  }
}