import 'package:equatable/equatable.dart';

class Service extends Equatable {
  final int? id;
  final String nama;
  final double harga;
  final String deskripsi;
  final String kategori; // Tambahan kolom kategori

  const Service({
    this.id,
    required this.nama,
    required this.harga,
    this.deskripsi = '',
    required this.kategori, // Wajib diisi
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nama': nama,
    'harga': harga,
    'deskripsi': deskripsi,
    'kategori': kategori,
  };

  factory Service.fromMap(Map<String, dynamic> map) => Service(
    id: map['id'],
    nama: map['nama'],
    harga: (map['harga'] as num).toDouble(), // Casting aman untuk double
    deskripsi: map['deskripsi'] ?? '',
    kategori: map['kategori'] ?? 'General', // Default jika null
  );

  @override
  List<Object?> get props => [id, nama, harga, deskripsi, kategori];
}

class ServiceCategory {
  static const String mesin = 'Mesin';
  static const String chassis = 'Chassis';
  static const String electrical = 'Electrical';
  static const String powertrain = 'Powertrain';
  static const String bodyAndPaint = 'Body & Paint';
  static const String generalService = 'General Service';
}
