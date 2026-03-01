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
  final String? namaMekanik;

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
    this.namaMekanik,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'no_wo': noWo,
        'tanggal': tanggal,
        'vehicle_id': vehicleId,
        'mechanic_id': mechanicId,
        'status': status,
        'total': total,
        'paid': paid,
      };

  factory WorkOrder.fromMap(Map<String, dynamic> map) => WorkOrder(
        id: map['id'],
        noWo: map['no_wo'],
        tanggal: map['tanggal'],
        vehicleId: map['vehicle_id'],
        mechanicId: map['mechanic_id'],
        status: map['status'],
        total: map['total'],
        paid: map['paid'] ?? 0,
        platNomor: map['plat_nomor'],
        merk: map['merk'],
        namaMekanik: map['nama_mekanik'],
      );

  @override
  List<Object?> get props => [id, noWo, status, total];
}