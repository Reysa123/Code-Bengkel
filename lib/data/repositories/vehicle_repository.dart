// 1. lib/data/repositories/vehicle_repository.dart
import '../../core/database/database_helper.dart';
import '../models/vehicle.dart';

class VehicleRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Vehicle>> getAll() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT vehicles.*, customers.nama AS nama_customer 
    FROM vehicles 
    LEFT JOIN customers ON vehicles.customer_id = customers.id
  ''');
    return maps.map((e) => Vehicle.fromMap(e)).toList();
  }

  Future<int> insert(Vehicle vehicle) async {
    final db = await dbHelper.database;
    return await db.insert('vehicles', vehicle.toMap());
  }

  Future<int> update(Vehicle vehicle) async {
    final db = await dbHelper.database;
    return await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbHelper.database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> cekKendaraan(int id) async {
    final db = await dbHelper.database;
    String mapss = "ok";
    final List<Map<String, dynamic>> maps = await db.query(
      'work_orders',
      where: 'vehicle_id = ? ',
      whereArgs: [id],
    );

    for (var e in maps) {
      if (e['status'] == 'pending' ||
          e['status'] == 'on_progress' ||
          e['status'] == 'completed' ||
          e['status'] == 'finished') {
        mapss = 'Kendaraan masih dalam proses perbaikan. WO No. ${e['no_wo']}';
      }
    }
    return mapss;
  }
}
