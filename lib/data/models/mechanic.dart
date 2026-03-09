import 'package:equatable/equatable.dart';

class Mechanic extends Equatable {
  final int? id;
  final String nama;
  final String noHp;

  const Mechanic({
    this.id,
    required this.nama,
    this.noHp = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'no_hp': noHp,
      };

  factory Mechanic.fromMap(Map<String, dynamic> map) => Mechanic(
        id: map['id'],
        nama: map['nama'],
        noHp: map['no_hp'] ?? '',
      );

  @override
  List<Object?> get props => [id, nama];
}