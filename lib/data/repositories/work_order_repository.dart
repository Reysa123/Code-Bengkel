// 6. lib/data/repositories/work_order_repository.dart  ← PALING PENTING

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database_helper.dart';
import '../models/work_order.dart';
import '../models/wo_item.dart';

class WorkOrderRepository {
  final dbHelper = DatabaseHelper.instance;
  Future<List<WorkOrder>> getAll({DateTimeRange? dateRange}) async {
    final db = await dbHelper.database;
    String where = '';
    List<dynamic> args = [];

    if (dateRange != null) {
      where = 'WHERE wo.tanggal BETWEEN ? AND ?';
      args = [
        DateFormat('yyyy-MM-dd').format(dateRange.start),
        DateFormat('yyyy-MM-dd').format(dateRange.end),
      ];
    }
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
    $where
    ORDER BY wo.tanggal ASC, wo.no_wo DESC
    ''', args);
    //print(maps.toList().toString());
    return maps.map((e) => WorkOrder.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getWoIdByNora(String nora) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT 
      wo.*,
      v.plat_nomor,
      v.merk,
      v.tipe,
      v.tahun,
      v.warna,
      v.nora,
      v.km_terakhir AS kmTerakhir,
      CASE 
        WHEN wi.type = 'service' THEN s.nama
        WHEN wi.type = 'part' THEN p.nama
        ELSE NULL
      END AS nama_item,
      CASE 
        WHEN wi.type = 'service' THEN s.harga
        WHEN wi.type = 'part' THEN p.harga_jual
        ELSE NULL
      END AS harga_item,
      wi.item_id AS id_item,
      wi.type AS type_item,
      wi.qty AS qty_item,
      wi.subtotal AS subtotal_item,
      wi.status AS status_item,
      c.nama AS nama_customer,
      c.alamat,
      c.no_hp,
      m.nama AS nama_mekanik
    FROM work_orders wo
    LEFT JOIN wo_items wi ON wo.no_wo = wi.wo_id
    LEFT JOIN services s ON wi.type = 'service' AND wi.item_id = s.id
    LEFT JOIN parts p ON wi.type = 'part' AND wi.item_id = p.id
    LEFT JOIN vehicles v ON wo.vehicle_id = v.id
    LEFT JOIN customers c ON v.customer_id = c.id
    LEFT JOIN mechanics m ON wo.mechanic_id = m.id
    WHERE v.nora LIKE ? OR v.plat_nomor LIKE ?
    ORDER BY wo.tanggal DESC
    ''',
      ['%$nora%', '%$nora%'],
    );
    return maps;
  }

  Future<List<Map<String, dynamic>>> getAllByWoId(String woId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT 
      wo.*,
      v.plat_nomor,
      v.merk,
      v.tipe,
      v.tahun,
      v.warna,
      v.nora,
      v.km_terakhir AS kmTerakhir,
      CASE 
        WHEN wi.type = 'service' THEN s.nama
        WHEN wi.type = 'part' THEN p.nama
        ELSE NULL
      END AS nama_item,
      CASE 
        WHEN wi.type = 'service' THEN s.harga
        WHEN wi.type = 'part' THEN p.harga_beli
        ELSE NULL
      END AS harga_beli_item,
      CASE 
        WHEN wi.type = 'service' THEN s.harga
        WHEN wi.type = 'part' THEN p.harga_jual
        ELSE NULL
      END AS harga_jual_item,
      wi.item_id AS item_id,
      wi.type AS type_item,
      wi.harga AS harga_item,
      wi.qty AS qty_item,
      wi.subtotal AS subtotal_item,
      wi.status AS status_item,
      c.nama AS nama_customer,
      c.alamat AS alamat_customer,
      c.no_hp AS hp_customer,
      m.nama AS nama_mekanik
    FROM work_orders wo
    LEFT JOIN wo_items wi ON wo.no_wo = wi.wo_id
    LEFT JOIN services s ON wi.type = 'service' AND wi.item_id = s.id
    LEFT JOIN parts p ON wi.type = 'part' AND wi.item_id = p.id
    LEFT JOIN vehicles v ON wo.vehicle_id = v.id
    LEFT JOIN customers c ON v.customer_id = c.id
    LEFT JOIN mechanics m ON wo.mechanic_id = m.id
    WHERE wo.no_wo = ?
    ''',
      [woId],
    );
    //print(maps.toList().toString());
    return maps;
  }

  Future<void> assignMechanics(String woId, List<int> mechanicIds) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // Hapus assignment lama
      //await txn.delete('work_order_mechanics', where: 'work_order_id = ?', whereArgs: [woId]);
      // Insert baru
      for (final mid in mechanicIds) {
        await txn.update(
          'work_orders',
          {'mechanic_id': mid, 'status': 'on_progress'},
          where: 'no_wo = ?',
          whereArgs: [woId],
        );
      }
    });
  }

  Future<int> insert(WorkOrder wo) async {
    final db = await dbHelper.database;
    return await db.insert('work_orders', wo.toMap());
  }

  Future<void> insertItem(List<WoItem> items) async {
    final db = await dbHelper.database;
    for (var item in items) {
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
      } catch (e) {
        throw Exception('Error inserting item: $e');
      }
    }
  }

  Future<void> insertWithItems(WorkOrder wo, List<WoItem> items) async {
    final db = await dbHelper.database;
    await db.insert('work_orders', wo.toMap());
    await db.update(
      'vehicles',
      {'km_terakhir': wo.kmTerakhir},
      where: 'id = ?',
      whereArgs: [wo.vehicleId],
    );
    for (var item in items) {
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
      } catch (e) {
        throw Exception('Error inserting item: $e');
      }
    }
  }

  Future<void> updateWithItems(WorkOrder wo, List<WoItem> items) async {
    final db = await dbHelper.database;
    //final woId = await insert(wo);
    try {
      await db.update(
        'work_orders',
        wo.toMap(),
        where: 'no_wo = ?',
        whereArgs: [wo.noWo],
      );
      await db.delete(
        'wo_items',
        where: 'wo_id = ? AND status = ?',
        whereArgs: [wo.noWo, 'pending'],
      );
      await db.update(
        'vehicles',
        {'km_terakhir': wo.kmTerakhir},
        where: 'id = ?',
        whereArgs: [wo.vehicleId],
      );
    } catch (e) {
      throw Exception('Error updating WO: $e');
    }
    for (var item in items) {
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
      } catch (e) {
        throw Exception('Error inserting item: $e');
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

  Future<void> cetakPartWorkOrder(int woId, {bool deductStock = true}) async {
    final db = await dbHelper.database;

    if (deductStock) {
      final sufficient = await checkStockSufficient(woId);
      if (!sufficient) {
        throw Exception('Stok beberapa part tidak mencukupi');
      }
      await deductPartStock(woId);
    }

    await db.update(
      'wo_items',
      {'status': 'completed'},
      where: 'wo_id = ? AND type = ?',
      whereArgs: [woId, 'part'],
    );
  }

  // Update status ke completed + optional deduct stock
  Future<void> completedWorkOrder(String woId) async {
    final db = await dbHelper.database;
    try {
      await db.update(
        'work_orders',
        {'status': 'completed'},
        where: 'no_wo = ?',
        whereArgs: [woId],
      );
      await db.update(
        'wo_items',
        {'status': 'completed'},
        where: 'wo_id=? AND type=?',
        whereArgs: [woId, 'service'],
      );
    } catch (e) {
      throw Exception('Error completing work order: $e');
    }
  }

  // Mengambil semua item dari Work Order tertentu
  Future<List<WoItem>> getWoItems(int woId, String status) async {
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
      WHERE wi.wo_id = ? AND wi.status = ?
      ORDER BY wi.id ASC
    ''',
      [woId, status],
    );
    // print('list : ${maps.toString()}');
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
  Future<void> kasirFinishWorkOrder(
    String woId,
    double paid,
    String nacus,
    String tgl,
  ) async {
    final db = await dbHelper.database;
    String tgls = DateTime.now().toIso8601String();
    await db.update(
      'work_orders',
      {'status': 'paid', 'paid': paid}, // atau 'completed_and_paid'
      where: 'no_wo = ?',
      whereArgs: [woId],
    );
    await db.insert('jurnal_umum', {
      'created_at': tgls,
      'tanggal': tgl,
      'no_referensi': 'PAY-$woId', // Nomor invoice penjualan
      'keterangan': 'Biaya Service Kendaraan $nacus',
      'kode_akun': '111',
      'nama_akun': 'Piutang Usaha',
      'debit': 0.00,
      'kredit': paid,
      'id_transaksi': woId,
      'dibuat_oleh': 'admin',
    });
    await db.insert('jurnal_umum', {
      'created_at': tgls,
      'tanggal': tgl,
      'no_referensi': 'PAY-$woId', // Nomor invoice penjualan
      'keterangan': 'Biaya Service Kendaraan $nacus',
      'kode_akun': '101',
      'nama_akun': 'Kas',
      'debit': paid,
      'kredit': 0.00,
      'id_transaksi': woId,
      'dibuat_oleh': 'admin',
    });
  }

  /// Membatalkan pembayaran work order
  /// Mengembalikan status work order & menghapus jurnal pembayaran terkait
  Future<bool> cancelPayment({
    required String woId,
    required String alasan,
    required String? dibuatOleh,
  }) async {
    final db = await dbHelper.database;

    try {
      await db.transaction((txn) async {
        // 1. Cek apakah work order memang sudah paid
        final woResult = await txn.query(
          'work_orders',
          where: 'no_wo = ?',
          whereArgs: [woId],
          limit: 1,
        );

        if (woResult.isEmpty) {
          throw Exception('Work order tidak ditemukan');
        }

        final wo = woResult.first;
        final currentStatus = wo['status'] as String?;

        if (currentStatus != 'paid') {
          throw Exception('Work order belum dibayar atau sudah dibatalkan');
        }

        // 2. Kembalikan status work order (misal ke 'completed' atau 'approved')
        await txn.update(
          'work_orders',
          {
            'status':
                'finished', // atau 'approved', 'in_progress' sesuai flow bisnis Anda
            'paid': 0.0,
          },
          where: 'no_wo = ?',
          whereArgs: [woId],
        );

        // 3. Hapus jurnal yang dibuat saat pembayaran
        // Biasanya ada 2 entri: Piutang Usaha (kredit) & Kas (debit)
        await txn.delete(
          'jurnal_umum',
          where: 'id_transaksi = ? AND no_referensi LIKE ?',
          whereArgs: [woId, 'PAY-%'],
        );

        // Opsional: catat log pembatalan
        await txn.insert('activity_logs', {
          'created_at': DateTime.now().toIso8601String(),
          'action': 'CANCEL_PAYMENT',
          'entity_type': 'work_order',
          'entity_id': woId,
          'description':
              'Pembayaran work order $woId dibatalkan, alasan : $alasan',
          'created_by': dibuatOleh,
          'old_value': woResult.first['paid'],
          'new_value': '0.0',
          'ip_address': "-",
          'user_agent': "-",
        });
      });

      return true;
    } catch (e) {
      debugPrint('Gagal membatalkan pembayaran: $e');
      return false;
    }
  }

  /// Optional: hanya mengembalikan status tanpa hapus jurnal (soft undo)
  Future<bool> revertToUnpaid(String woId) async {
    final db = await dbHelper.database;
    final count = await db.update(
      'work_orders',
      {'status': 'completed', 'paid': 0.0},
      where: 'no_wo = ?',
      whereArgs: [woId],
    );
    return count > 0;
  }

  // Finish WO + cetak kwitansi
  Future<void> finishWorkOrderAndPrint(
    int woId,
    double paid,
    List<WoItem> items,
    String nacus,
  ) async {
    String tgl = DateTime.now().toIso8601String();
    final db = await dbHelper.database;
    final wo = await getAllByWoId(woId.toString());
    double hpart = 0, pendapatanpart = 0, pendapatanjasa = 0;
    String plat = wo.first['plat_nomor'];
    for (var e in wo) {
      if (e['type_item'] == 'part') {
        hpart += e['harga_beli_item'] * e['qty_item'];
        pendapatanpart += e['harga_jual_item'] * e['qty_item'];
      }
      if (e['type_item'] == 'service') {
        pendapatanjasa += e['harga_jual_item'] * e['qty_item'];
      }
    }
    double disc = (pendapatanpart + pendapatanjasa) - paid;
    await db.insert('jurnal_umum', {
      'created_at': tgl,
      'tanggal': wo.first['tanggal'],
      'no_referensi': 'BIL-$woId', // Nomor invoice penjualan
      'keterangan': 'Biaya Service Kendaraan $nacus-$plat',
      'kode_akun': '111',
      'nama_akun': 'Piutang Usaha',
      'debit': paid,
      'kredit': 0.00,
      'id_transaksi': woId,
      'dibuat_oleh': 'admin',
    });
    await db.insert('jurnal_umum', {
      'created_at': tgl,
      'tanggal': wo.first['tanggal'],
      'no_referensi': 'BIL-$woId', // Nomor invoice penjualan
      'keterangan': 'Biaya Service Kendaraan $nacus-$plat',
      'kode_akun': '501',
      'nama_akun': 'Harga Pokok Penjualan Part',
      'debit': hpart,
      'kredit': 0.00,
      'id_transaksi': woId,
      'dibuat_oleh': 'admin',
    });
    await db.insert('jurnal_umum', {
      'created_at': tgl,
      'tanggal': wo.first['tanggal'],
      'no_referensi': 'BIL-$woId', // Nomor invoice penjualan
      'keterangan': 'Disc Biaya Service Kendaraan $nacus-$plat',
      'kode_akun': '602',
      'nama_akun': 'Beban Discount',
      'debit': disc,
      'kredit': 0.00,
      'id_transaksi': woId,
      'dibuat_oleh': 'admin',
    });
    await db.insert('jurnal_umum', {
      'created_at': tgl,
      'tanggal': wo.first['tanggal'],
      'no_referensi': 'BIL-$woId', // Nomor invoice penjualan
      'keterangan': 'Biaya Service Kendaraan $nacus-$plat',
      'kode_akun': '401',
      'nama_akun': 'Pendapatan Jasa/Service',
      'debit': 0.00,
      'kredit': pendapatanjasa,
      'id_transaksi': woId,
      'dibuat_oleh': 'admin',
    });
    await db.insert('jurnal_umum', {
      'created_at': tgl,
      'tanggal': wo.first['tanggal'],
      'no_referensi': 'BIL-$woId', // Nomor invoice penjualan
      'keterangan': 'Biaya Service Kendaraan $nacus-$plat',
      'kode_akun': '402',
      'nama_akun': 'Pendapatan Penjualan Part',
      'debit': 0.00,
      'kredit': pendapatanpart,
      'id_transaksi': woId,
      'dibuat_oleh': 'admin',
    });
    await db.insert('jurnal_umum', {
      'created_at': tgl,
      'tanggal': wo.first['tanggal'],
      'no_referensi': 'BIL-$woId', // Nomor invoice penjualan
      'keterangan': 'Biaya Service Kendaraan $nacus-$plat',
      'kode_akun': '121',
      'nama_akun': 'Persediaan Sparepart',
      'debit': 0.00,
      'kredit': hpart,
      'id_transaksi': woId,
      'dibuat_oleh': 'admin',
    });
    await db.update(
      'work_orders',
      {
        'status': 'finished',
        'paid': paid,
      }, // atau 'paid' / 'completed_and_paid'
      where: 'no_wo = ?',
      whereArgs: [woId],
    );
    for (var item in items) {
      await db.update(
        'wo_items',
        {'discount_percent': item.discountPercent},
        where: 'id = ?',
        whereArgs: [item.id],
      );
    }

    // // Optional: update paid = total jika belum lunas
    // await db.rawUpdate(
    //   'UPDATE work_orders SET paid = total WHERE id = ? AND paid < total',
    //   [woId],
    // );
  }
Future<bool> undoFinishWorkOrder({
  required String woId,
  required String alasan,
  required String dibuatOleh,
}) async {
  final db = await dbHelper.database;

  try {
    await db.transaction((txn) async {
      // 1. Cek status
      final wo = await txn.query(
        'work_orders',
        where: 'no_wo = ?',
        whereArgs: [woId],
        limit: 1,
      );

      if (wo.isEmpty || wo.first['status'] != 'finished') {
        throw Exception('WO tidak ditemukan atau bukan status finished');
      }

      // 2. Kembalikan status (sesuaikan dengan flow Anda)
      await txn.update(
        'work_orders',
        {'status': 'completed', 'paid': 0.0}, // atau 'in_progress', 'completed', dll
        where: 'no_wo = ?',
        whereArgs: [woId],
      );

      // 3. Hapus semua jurnal dengan no_referensi = BIL-$woId
      await txn.delete(
        'jurnal_umum',
        where: 'no_referensi = ?',
        whereArgs: ['BIL-$woId'],
      );

      // 4. Catat log (opsional tapi sangat disarankan)
      await txn.insert('activity_logs', {
        'created_at': DateTime.now().toIso8601String(),
        'action': 'UNDO_FINISH_WORK_ORDER',
        'entity_type': 'work_order',
        'entity_id': woId.toString(),
        'description': 'Penyelesaian WO $woId dibatalkan. Alasan: $alasan',
        'created_by': dibuatOleh,
        'old_value': 'finished',
        'new_value': 'completed',
        'ip_address': '-',
        'user_agent': '-',
      });
    });

    return true;
  } catch (e) {
    debugPrint('Gagal undo finish WO: $e');
    return false;
  }
}
  // Ambil data lengkap untuk kwitansi (sudah include diskon)
  Future<Map<String, dynamic>> getWorkOrderForReceipt(String woId) async {
    final db = await dbHelper.database;
    //print('Fetching WO for receipt: $woId');
    final woMap = await db.query(
      'work_orders',
      where: 'no_wo = ?',
      whereArgs: [woId],
      limit: 1,
    );

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
    // print('Items for receipt: ${woMap.toString()}');
    return {'wo': woMap.first, 'items': items};
  }
}
