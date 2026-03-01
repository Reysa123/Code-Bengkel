import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  final int? id;
  final int? customerId;
  final String platNomor;
  final String merk;
  final String tipe;
  final String tahun;
  final String warna;

  const Vehicle({
    this.id,
    this.customerId,
    required this.platNomor,
    required this.merk,
    required this.tipe,
    required this.tahun,
    this.warna = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'plat_nomor': platNomor,
        'merk': merk,
        'tipe': tipe,
        'tahun': tahun,
        'warna': warna,
      };

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle(
        id: map['id'],
        customerId: map['customer_id'],
        platNomor: map['plat_nomor'],
        merk: map['merk'],
        tipe: map['tipe'],
        tahun: map['tahun'],
        warna: map['warna'] ?? '',
      );

  @override
  List<Object?> get props => [id, platNomor];
}