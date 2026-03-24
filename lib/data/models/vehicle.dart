import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  final int? id;
  final int? customerId;
  final String platNomor;
  final String nora;
  final String merk;
  final String tipe;
  final String tahun;
  final String warna;
  final String? namaCustomer;
  final int? kmTerakhir;

  const Vehicle({
    this.id,
    this.customerId,
    required this.platNomor,
    required this.nora,
    required this.merk,
    required this.tipe,
    required this.tahun,
    this.warna = '',
    this.namaCustomer,
    this.kmTerakhir,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'customer_id': customerId,
    'plat_nomor': platNomor,
    'nora': nora,
    'merk': merk,
    'tipe': tipe,
    'tahun': tahun,
    'warna': warna,
    'km_terakhir': kmTerakhir ?? 0,
  };

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle(
    id: map['id'],
    customerId: map['customer_id'],
    platNomor: map['plat_nomor'],
    nora: map['nora'],
    merk: map['merk'],
    tipe: map['tipe'],
    tahun: map['tahun'],
    warna: map['warna'] ?? '',
    namaCustomer: map['nama_customer'],
    kmTerakhir: map['km_terakhir'] ?? 0,
  );

  @override
  List<Object?> get props => [id, platNomor, kmTerakhir, nora];
}
