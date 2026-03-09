// lib/data/repositories/customer_repository.dart

import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../models/customer.dart';

class CustomerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Mendapatkan semua pelanggan, diurutkan berdasarkan nama
  Future<List<Customer>> getAllCustomers() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'nama ASC',
    );

    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Mendapatkan pelanggan berdasarkan ID
  Future<Customer?> getCustomerById(int id) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  /// Mencari pelanggan berdasarkan nama atau nomor HP (partial match)
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'nama LIKE ? OR no_hp LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'nama ASC',
    );

    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Menyimpan pelanggan baru → mengembalikan ID yang baru dibuat
  Future<int> insertCustomer(Customer customer) async {
    final db = await _dbHelper.database;

    return await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Memperbarui data pelanggan
  Future<int> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;

    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  /// Menghapus pelanggan berdasarkan ID
  /// Catatan: Sebaiknya cek dulu apakah pelanggan ini masih punya kendaraan
  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.database;

    // Optional: cek apakah ada kendaraan terkait
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM vehicles WHERE customer_id = ?',
      [id],
    ));

    if ((count ?? 0) > 0) {
      throw Exception('Pelanggan ini masih memiliki kendaraan terkait');
    }

    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mendapatkan jumlah total pelanggan (untuk dashboard/statistik)
  Future<int> getCustomerCount() async {
    final db = await _dbHelper.database;
    return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM customers'),
    ) ?? 0;
  }

  /// Mendapatkan pelanggan beserta jumlah kendaraan yang dimiliki
  /// (berguna untuk tampilan list pelanggan yang lebih informatif)
  Future<List<Map<String, dynamic>>> getCustomersWithVehicleCount() async {
    final db = await _dbHelper.database;

    return await db.rawQuery('''
      SELECT 
        c.id,
        c.nama,
        c.no_hp,
        c.alamat,
        COUNT(v.id) as vehicle_count
      FROM customers c
      LEFT JOIN vehicles v ON c.id = v.customer_id
      GROUP BY c.id
      ORDER BY c.nama ASC
    ''');
  }
}