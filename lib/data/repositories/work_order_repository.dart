// 6. lib/data/repositories/work_order_repository.dart  ← PALING PENTING

import '../../core/database/database_helper.dart';
import '../models/work_order.dart';
import '../models/wo_item.dart';

class WorkOrderRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<WorkOrder>> getAll() async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT wo.*, v.plat_nomor, v.merk, m.nama as nama_mekanik 
      FROM work_orders wo
      LEFT JOIN vehicles v ON wo.vehicle_id = v.id
      LEFT JOIN mechanics m ON wo.mechanic_id = m.id
      ORDER BY wo.tanggal DESC
    ''');
    return maps.map((e) => WorkOrder.fromMap(e)).toList();
  }

  Future<int> insert(WorkOrder wo) async {
    final db = await dbHelper.database;
    return await db.insert('work_orders', wo.toMap());
  }

  Future<void> insertWithItems(WorkOrder wo, List<WoItem> items) async {
    final db = await dbHelper.database;
    final woId = await insert(wo);

    for (var item in items) {
      // item.woId = woId;
      await db.insert('wo_items', {
        'id': item.id,
        'wo_id': woId,
        'type': item.type,
        'item_id': item.itemId,
        'nama_item': item.namaItem,
        'qty': item.qty,
        'harga': item.harga,
        'subtotal': item.subtotal,
      });

      // Kurangi stok jika part
      if (item.type == 'part') {
        await db.rawUpdate('UPDATE parts SET stok = stok - ? WHERE id = ?', [
          item.qty,
          item.itemId,
        ]);
      }
    }
  }

  Future<int> updateStatus(int woId, String status, double paid) async {
    final db = await dbHelper.database;
    return await db.update(
      'work_orders',
      {'status': status, 'paid': paid},
      where: 'id = ?',
      whereArgs: [woId],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbHelper.database;
    await db.delete('wo_items', where: 'wo_id = ?', whereArgs: [id]);
    return await db.delete('work_orders', where: 'id = ?', whereArgs: [id]);
  }
}
