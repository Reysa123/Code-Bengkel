// lib/data/models/customer.dart

import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int? id;
  final String nama;
  final String? noHp;
  final String? alamat;

  const Customer({
    this.id,
    required this.nama,
    this.noHp,
    this.alamat,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'no_hp': noHp,
      'alamat': alamat,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      noHp: map['no_hp'] as String?,
      alamat: map['alamat'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, nama, noHp, alamat];

  @override
  bool get stringify => true;
}