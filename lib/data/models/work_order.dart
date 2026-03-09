import 'package:equatable/equatable.dart';

class WorkOrder extends Equatable {
  final int? id;
  final String noWo;
  final String tanggal;
  final int vehicleId;
  final int mechanicId;
  final String status;
  final double total;
  final double paid;

  // untuk tampilan di list (opsional)
  final String? platNomor;
  final String? merk;
  final String? tipe;
  final int? tahun;
  final String? warna;
  final String? namaCustomer;
  final String? namaMekanik;
  final String? catatan;
  final int? kmTerakhir;

  const WorkOrder({
    this.id,
    required this.noWo,
    required this.tanggal,
    required this.vehicleId,
    required this.mechanicId,
    this.status = 'pending',
    required this.total,
    this.paid = 0,
    this.platNomor,
    this.merk,
    this.tipe,
    this.tahun,
    this.warna,
    this.namaCustomer,
    this.namaMekanik,
    this.catatan,
    this.kmTerakhir,
  });

  Map<String, dynamic> toMap() => {
    // 'id': id,
    'no_wo': noWo,
    'tanggal': tanggal,
    'vehicle_id': vehicleId,
    'mechanic_id': mechanicId,
    'status': status,
    'total': total,
    'paid': paid,
    'catatan': catatan,
    'km_terakhir': kmTerakhir,
  };

  factory WorkOrder.fromMap(Map<String, dynamic> map) => WorkOrder(
    id: int.parse(map['id'].toString()),
    noWo: map['no_wo'].toString(),
    tanggal: map['tanggal'],
    vehicleId: map['vehicle_id'],
    namaCustomer: map['nama_customer'],
    mechanicId: map['mechanic_id'],
    status: map['status'],
    total: map['total'],
    paid: map['paid'],
    platNomor: map['plat_nomor'],
    merk: map['merk'],
    tipe: map['tipe'],
    tahun: int.parse(map['tahun'].toString()),
    warna: map['warna'],
    namaMekanik: map['nama_mekanik'],
    catatan: map['catatan'],
    kmTerakhir: map['km_terakhir'],
  );

  @override
  List<Object?> get props => [
    id,
    noWo,
    tanggal,
    vehicleId,
    mechanicId,
    status,
    total,
    paid,
    platNomor,
    merk,
    tipe,
    tahun,
    warna,
    namaCustomer,
    namaMekanik,
    catatan,
    kmTerakhir,
  ];
}
