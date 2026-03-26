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

  Future<void> insertJurnal(
    String tgl,
    String nospk,
    String desc,
    double hargaModal,
    double hargaJual,
    int nowo,
  ) async {
    final db = await _db;
    String tgls = DateTime.now().toIso8601String();
    await db.insert('jurnal_umum', {
      'created_at': tgls,
      'tanggal': tgl,
      'no_referensi': nospk, // Nomor invoice penjualan
      'keterangan': desc,
      'kode_akun': '502',
      'nama_akun': 'HPP Jasa Sublet',
      'debit': hargaModal,
      'kredit': 0.0,
      'id_transaksi': nowo,
      'dibuat_oleh': 'admin',
    });
    await db.insert('jurnal_umum', {
      'created_at': tgls,
      'tanggal': tgl,
      'no_referensi': nospk, // Nomor invoice penjualan
      'keterangan': desc,
      'kode_akun': '202',
      'nama_akun': 'Hutang Pihak Ketiga (Sublet)',
      'debit': 0.0,
      'kredit': hargaModal,
      'id_transaksi': nowo,
      'dibuat_oleh': 'admin',
    });
  }

  Future<void> postJurnal(
    String tgl,
    String nospk,
    String vendor,
    double hargaModal,
    int nowo,
    List<int> id,
  ) async {
    final db = await _db;
    String tgls = DateTime.now().toIso8601String();
    await db.insert('jurnal_umum', {
      'created_at': tgls,
      'tanggal': tgl,
      'no_referensi': 'PAY-$nospk', // Nomor invoice penjualan
      'keterangan': 'Pelunasan Sublet ke $vendor',
      'kode_akun': '202',
      'nama_akun': 'Hutang Pihak Ketiga (Sublet)',
      'debit': hargaModal,
      'kredit': 0.00,
      'id_transaksi': nowo,
      'dibuat_oleh': 'admin',
    });
    await db.insert('jurnal_umum', {
      'created_at': tgls,
      'tanggal': tgl,
      'no_referensi': 'PAY-$nospk', // Nomor invoice penjualan
      'keterangan': 'Pelunasan Sublet ke $vendor',
      'kode_akun': '101',
      'nama_akun': 'Kas',
      'debit': 0.00,
      'kredit': hargaModal,
      'id_transaksi': nowo,
      'dibuat_oleh': 'admin',
    });
    for (var e in id) {
      await db.update(
        'external_orders',
        {'status': 'Lunas'},
        where: 'id = ?',
        whereArgs: [e],
      );
    }
  }

  Future<int> update(int id, String nospk) async {
    final db = await _db;

    return await db.update(
      'external_orders',
      {'nospk': nospk},
      where: 'id = ?',
      whereArgs: [id],
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
      await db.delete(
        "jurnal_umum",
        where: 'no_referensi = ?',
        whereArgs: [v.first['nospk']],
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
    final result = await db.query(
      'external_orders',
      orderBy: 'id DESC',
      where: 'status != ?',
      whereArgs: ['Lunas'],
    );
    return result.map((row) => ExternalOrder.fromMap(row)).toList();
  }
}
