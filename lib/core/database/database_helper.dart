import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bengkel.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama TEXT NOT NULL, no_hp TEXT, alamat TEXT
    )''');

    await db.execute('''CREATE TABLE vehicles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER, plat_nomor TEXT UNIQUE NOT NULL,
      merk TEXT, tipe TEXT, tahun TEXT, warna TEXT, km_terakhir INTEGER DEFAULT 0,
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    )''');

    await db.execute('''
  CREATE TABLE services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nama TEXT NOT NULL,
    harga REAL NOT NULL,
    deskripsi TEXT,
    kategori TEXT NOT NULL CHECK (kategori IN (
      'Mesin', 
      'Chassis', 
      'Electrical', 
      'Powertrain', 
      'Body & Paint', 
      'General Service'
    ))
  )
''');

    await db.execute('''CREATE TABLE parts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      kode TEXT UNIQUE, nama TEXT NOT NULL, stok INTEGER DEFAULT 0,
      harga_beli REAL, harga_jual REAL, supplier_id INTEGER,
      FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
    )''');

    await db.execute('''CREATE TABLE mechanics (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama TEXT NOT NULL, no_hp TEXT
    )''');

    await db.execute('''CREATE TABLE suppliers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama TEXT NOT NULL, no_hp TEXT, alamat TEXT
    )''');

    await db.execute('''CREATE TABLE work_orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      no_wo TEXT UNIQUE NOT NULL, tanggal TEXT NOT NULL,
      vehicle_id INTEGER, mechanic_id INTEGER,
      catatan TEXT,km_terakhir INTEGER DEFAULT 0,
      status TEXT DEFAULT 'pending', total REAL DEFAULT 0, paid REAL DEFAULT 0,
      FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
      FOREIGN KEY (mechanic_id) REFERENCES mechanics(id)
    )''');

    await db.execute('''CREATE TABLE wo_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      wo_id INTEGER, type TEXT, item_id INTEGER,
      qty INTEGER DEFAULT 1, harga REAL, discount_percent REAL DEFAULT 0, subtotal REAL,status TEXT DEFAULT 'pending',
      FOREIGN KEY (wo_id) REFERENCES work_orders(id)
    )''');

    await db.execute('''CREATE TABLE purchases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      no_purchase TEXT UNIQUE, tanggal TEXT,
      supplier_id INTEGER, total REAL, status TEXT DEFAULT 'pending',
      FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
    )''');

    await db.execute('''CREATE TABLE purchase_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      purchase_id INTEGER, part_id INTEGER, qty INTEGER, harga_beli REAL,
      FOREIGN KEY (purchase_id) REFERENCES purchases(id),
      FOREIGN KEY (part_id) REFERENCES parts(id)
    )''');

    await db.execute('''CREATE TABLE external_orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      no_order TEXT, tanggal TEXT, wo_id INTEGER,
      deskripsi TEXT, biaya REAL, vendor TEXT,
      FOREIGN KEY (wo_id) REFERENCES work_orders(id)
    )''');

    await db.execute('''CREATE TABLE payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      wo_id INTEGER, tanggal TEXT, amount REAL, metode TEXT,
      FOREIGN KEY (wo_id) REFERENCES work_orders(id)
    )''');
  }
}
