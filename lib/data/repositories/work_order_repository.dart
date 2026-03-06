// 6. lib/data/repositories/work_order_repository.dart  ← PALING PENTING

import '../../core/database/database_helper.dart';
import '../models/work_order.dart';
import '../models/wo_item.dart';

class WorkOrderRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<WorkOrder>> getAll() async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT 
      wo.*,
      v.plat_nomor,
      v.merk,
      v.tipe,
      v.tahun,
      v.warna,
      c.nama AS nama_customer,
      m.nama AS nama_mekanik
    FROM work_orders wo
    LEFT JOIN vehicles v ON wo.vehicle_id = v.id
    LEFT JOIN customers c ON v.customer_id = c.id
    LEFT JOIN mechanics m ON wo.mechanic_id = m.id
    ORDER BY wo.tanggal DESC
    ''');
    print(maps.toList().toString());
    return maps.map((e) => WorkOrder.fromMap(e)).toList();
  }

  Future<void> assignMechanics(String woId, List<int> mechanicIds) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // Hapus assignment lama
      //await txn.delete('work_order_mechanics', where: 'work_order_id = ?', whereArgs: [woId]);
      print('Deleted old mechanics for WO $woId');
      print('Assigning new mechanics: $mechanicIds');
      // Insert baru
      for (final mid in mechanicIds) {
        await txn.update('work_orders', {'no_wo': woId, 'mechanic_id': mid});
      }
    });
  }

  Future<int> insert(WorkOrder wo) async {
    final db = await dbHelper.database;
    return await db.insert('work_orders', wo.toMap());
  }

  Future<void> insertWithItems(WorkOrder wo, List<WoItem> items) async {
    print('Inserting Work Order: ${items.map((i) => i.toString()).toList()}');
    final db = await dbHelper.database;
    //final woId = await insert(wo);
    // await db.insert('work_orders', wo.toMap());
    print(items.length);
    for (var item in items) {
      print(item.toString());
      // item.woId = woId;
      try {
        await db.insert('wo_items', {
          'wo_id': item.woId,
          'type': item.type,
          'item_id': item.itemId,
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
      } catch (e) {
        print('Error inserting item: $e');
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

  Future<int> updateMechanic(
    int woId,
    int mechanicId, {
    String? newStatus,
  }) async {
    final db = await dbHelper.database;
    Map<String, dynamic> map = {};
    map['mechanic_id'] = mechanicId;
    if (newStatus != null) {
      map['status'] = newStatus;
    }
    return await db.update(
      'work_orders',
      map,
      where: 'id = ?',
      whereArgs: [woId],
    );
  }

  // Cek apakah stok cukup untuk semua part di WO ini
  Future<bool> checkStockSufficient(int woId) async {
    final db = await dbHelper.database;

    final items = await db.rawQuery(
      '''
    SELECT wi.item_id, wi.qty, p.stok
    FROM wo_items wi
    JOIN parts p ON wi.item_id = p.id
    WHERE wi.wo_id = ? AND wi.type = 'part'
  ''',
      [woId],
    );

    for (var row in items) {
      final required = row['qty'] as int;
      final available = row['stok'] as int;
      if (available < required) {
        return false;
      }
    }
    return true;
  }

  // Kurangi stok semua part di WO ini
  Future<void> deductPartStock(int woId) async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      final items = await txn.rawQuery(
        '''
      SELECT item_id, qty FROM wo_items WHERE wo_id = ? AND type = 'part'
    ''',
        [woId],
      );

      for (var row in items) {
        final partId = row['item_id'] as int;
        final qty = row['qty'] as int;

        await txn.rawUpdate('UPDATE parts SET stok = stok - ? WHERE id = ?', [
          qty,
          partId,
        ]);
      }
    });
  }

  // Update status ke completed + optional deduct stock
  Future<void> completeWorkOrder(int woId, {bool deductStock = true}) async {
    final db = await dbHelper.database;

    if (deductStock) {
      final sufficient = await checkStockSufficient(woId);
      if (!sufficient) {
        throw Exception('Stok beberapa part tidak mencukupi');
      }
      await deductPartStock(woId);
    }

    await db.update(
      'work_orders',
      {'status': 'completed'},
      where: 'no_wo = ?',
      whereArgs: [woId],
    );
  }

  // Mengambil semua item dari Work Order tertentu
  Future<List<WoItem>> getWoItems(int woId) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        wi.*,
        CASE
          WHEN wi.type = 'service' THEN s.nama
          WHEN wi.type = 'part' THEN p.nama
        END AS nama_item,
        CASE
          WHEN wi.type = 'service' THEN s.harga
          WHEN wi.type = 'part' THEN p.harga_jual
          ELSE wi.harga
        END AS harga
      FROM wo_items wi
      LEFT JOIN services s ON wi.item_id = s.id AND wi.type = 'service'
      LEFT JOIN parts p ON wi.item_id = p.id AND wi.type = 'part'
      WHERE wi.wo_id = ?
      ORDER BY wi.id ASC
    ''',
      [woId],
    );
    print('list : ${maps.toString()}');
    return maps.map((map) {
      // Buat WoItem dengan data tambahan (display name & harga asli jika perlu)
      final item = WoItem.fromMap(map);
      return item;

      // Optional: tambahkan field custom jika model WoItem sudah di-extend
      // item.namaItem = map['nama_item_display'] as String? ?? item.namaItem;
    }).toList();
  }

  // Versi alternatif: kembalikan Map lengkap (lebih fleksibel untuk cetak)
  Future<List<Map<String, dynamic>>> getWoItemsDetailed(int woId) async {
    final db = await dbHelper.database;

    return await db.rawQuery(
      '''
    SELECT 
      wi.id,
      wi.type,
      wi.item_id,
      wi.qty,
      wi.harga,
      wi.subtotal,
      CASE 
        WHEN wi.type = 'service' THEN s.nama
        WHEN wi.type = 'part' THEN p.nama || ' (' || p.kode || ')'
       
      END AS nama_item,
      CASE 
        WHEN wi.type = 'service' THEN s.harga
        WHEN wi.type = 'part' THEN p.harga_jual
        ELSE wi.harga
      END AS harga_asli,
      CASE 
        WHEN wi.type = 'part' THEN p.stok
        ELSE NULL
      END AS stok_saat_ini
    FROM wo_items wi
    LEFT JOIN services s ON wi.type = 'service' AND wi.item_id = s.id
    LEFT JOIN parts p ON wi.type = 'part' AND wi.item_id = p.id
    WHERE wi.wo_id = ?
    ORDER BY wi.id ASC
  ''',
      [woId],
    );
  }
  // lib/data/repositories/work_order_repository.dart

  // Finish WO + cetak kwitansi
  Future<void> finishWorkOrderAndPrint(int woId) async {
    final db = await dbHelper.database;

    await db.update(
      'work_orders',
      {'status': 'finished'}, // atau 'paid' / 'completed_and_paid'
      where: 'id = ?',
      whereArgs: [woId],
    );

    // Optional: update paid = total jika belum lunas
    await db.rawUpdate(
      'UPDATE work_orders SET paid = total WHERE id = ? AND paid < total',
      [woId],
    );
  }

  // Ambil data lengkap untuk kwitansi (sudah include diskon)
  Future<Map<String, dynamic>> getWorkOrderForReceipt(int woId) async {
    final db = await dbHelper.database;

    final woMap = await db.query('work_orders', where: 'id = ?', limit: 1);

    if (woMap.isEmpty) throw Exception('WO tidak ditemukan');

    final items = await db.rawQuery(
      '''
    SELECT 
      wi.*,
      CASE 
        WHEN wi.type = 'service' THEN s.nama
        WHEN wi.type = 'part' THEN p.nama || ' (' || p.kode || ')'
        
      END AS nama_item,
      wi.discount_percent
    FROM wo_items wi
    LEFT JOIN services s ON wi.type = 'service' AND wi.item_id = s.id
    LEFT JOIN parts p ON wi.type = 'part' AND wi.item_id = p.id
    WHERE wi.wo_id = ?
  ''',
      [woId],
    );

    return {'wo': woMap.first, 'items': items};
  }
}
