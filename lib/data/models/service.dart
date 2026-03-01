import 'package:equatable/equatable.dart';

class Service extends Equatable {
  final int? id;
  final String nama;
  final double harga;
  final String deskripsi;

  const Service({
    this.id,
    required this.nama,
    required this.harga,
    this.deskripsi = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'harga': harga,
        'deskripsi': deskripsi,
      };

  factory Service.fromMap(Map<String, dynamic> map) => Service(
        id: map['id'],
        nama: map['nama'],
        harga: map['harga'],
        deskripsi: map['deskripsi'] ?? '',
      );

  @override
  List<Object?> get props => [id, nama, harga];
}