import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final int? id;
  final String nama;
  final String noHp;
  final String alamat;

  const Supplier({
    this.id,
    required this.nama,
    this.noHp = '',
    this.alamat = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'no_hp': noHp,
        'alamat': alamat,
      };

  factory Supplier.fromMap(Map<String, dynamic> map) => Supplier(
        id: map['id'],
        nama: map['nama'],
        noHp: map['no_hp'] ?? '',
        alamat: map['alamat'] ?? '',
      );

  @override
  List<Object?> get props => [id, nama];
}