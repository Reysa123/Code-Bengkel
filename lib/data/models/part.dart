import 'package:equatable/equatable.dart';

class Part extends Equatable {
  final int? id;
  final String kode;
  final String nama;
  final int stok;
  final double hargaBeli;
  final double hargaJual;
  final int? supplierId;

  const Part({
    this.id,
    required this.kode,
    required this.nama,
    this.stok = 0,
    this.hargaBeli = 0,
    required this.hargaJual,
    this.supplierId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'kode': kode,
        'nama': nama,
        'stok': stok,
        'harga_beli': hargaBeli,
        'harga_jual': hargaJual,
        'supplier_id': supplierId,
      };

  factory Part.fromMap(Map<String, dynamic> map) => Part(
        id: map['id'],
        kode: map['kode'] ?? '',
        nama: map['nama'],
        stok: map['stok'] ?? 0,
        hargaBeli: map['harga_beli'] ?? 0,
        hargaJual: map['harga_jual'],
        supplierId: map['supplier_id'],
      );

  @override
  List<Object?> get props => [id, kode, nama, stok];
}