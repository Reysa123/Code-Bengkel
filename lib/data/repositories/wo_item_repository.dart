// lib/data/repositories/wo_item_repository.dart


import '../../core/database/database_helper.dart';
import '../models/wo_item.dart';

class WoItemRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Mendapatkan semua item dari satu Work Order tertentu
  Future<List<WoItem>> getItemsByWoId(int woId) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'wo_items',
      where: 'wo_id = ?',
      whereArgs: [woId],
      orderBy: 'id ASC',
    );

    return maps.map((map) => WoItem.fromMap(map)).toList();
  }

  /// Mendapatkan satu WoItem berdasarkan ID
  Future<WoItem?> getWoItemById(int id) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'wo_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return WoItem.fromMap(maps.first);
    }
    return null;
  }

  /// Menyimpan satu item baru (atau banyak item sekaligus)
  Future<int> insert(WoItem item) async {
    final db = await _dbHelper.database;
    return await db.insert('wo_items', item.toMap());
  }

  /// Menyimpan banyak item sekaligus (batch insert)
  Future<void> insertMultiple(List<WoItem> items) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final item in items) {
      batch.insert('wo_items', item.toMap());
    }

    await batch.commit(noResult: true);
  }

  /// Update satu item (misalnya ubah qty atau harga)
  Future<int> update(WoItem item) async {
    final db = await _dbHelper.database;
    return await db.update(
      'wo_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Update qty saja (lebih ringan, sering dipakai)
  Future<int> updateQty(int id, int newQty) async {
    final db = await _dbHelper.database;
    return await db.update(
      'wo_items',
      {'qty': newQty},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hapus satu item berdasarkan ID
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'wo_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hapus SEMUA item dari satu Work Order (biasanya dipakai saat hapus WO)
  Future<int> deleteByWoId(int woId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'wo_items',
      where: 'wo_id = ?',
      whereArgs: [woId],
    );
  }

  /// Mendapatkan total subtotal dari semua item di satu WO
  Future<double> getTotalSubtotalByWoId(int woId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT SUM(subtotal) as total
      FROM wo_items
      WHERE wo_id = ?
    ''', [woId]);

    final total = result.first['total'] as num?;
    return (total ?? 0).toDouble();
  }

  /// Mendapatkan semua item beserta info part/service (untuk tampilan detail/invoice)
  Future<List<Map<String, dynamic>>> getDetailedItemsByWoId(int woId) async {
    final db = await _dbHelper.database;

    return await db.rawQuery('''
      SELECT 
        wi.*,
        CASE 
          WHEN wi.type = 'service' THEN s.nama
          WHEN wi.type = 'part' THEN p.nama
          ELSE wi.nama_item
        END as display_name,
        CASE 
          WHEN wi.type = 'service' THEN s.harga
          WHEN wi.type = 'part' THEN p.harga_jual
          ELSE wi.harga
        END as original_price
      FROM wo_items wi
      LEFT JOIN services s ON wi.type = 'service' AND wi.item_id = s.id
      LEFT JOIN parts p ON wi.type = 'part' AND wi.item_id = p.id
      WHERE wi.wo_id = ?
      ORDER BY wi.id ASC
    ''', [woId]);
  }

  //Mengembalikan stok jika item part dihapus dari WO
  Future<int> deleteBack(int id) async {
  final db = await _dbHelper.database;

  // Ambil data item dulu
  final item = await getWoItemById(id);
  if (item != null && item.type == 'part') {
    // Kembalikan stok
    await db.rawUpdate(
      'UPDATE parts SET stok = stok + ? WHERE id = ?',
      [item.qty, item.itemId],
    );
  }

  return await db.delete('wo_items', where: 'id = ?', whereArgs: [id]);
}
}