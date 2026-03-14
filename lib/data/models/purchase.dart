import 'package:equatable/equatable.dart';

class Purchase extends Equatable {
  final int? id;
  final String noPurchase;
  final String tanggal;
  final int supplierId;
  final double total;
  final String status; // 'pending', 'completed', 'cancelled'

  const Purchase({
    this.id,
    required this.noPurchase,
    required this.tanggal,
    required this.supplierId,
    required this.total,
    this.status = 'completed',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'no_purchase': noPurchase,
      'tanggal': tanggal,
      'supplier_id': supplierId,
      'total': total,
      'status': status,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      noPurchase: map['no_purchase'] as String,
      tanggal: map['tanggal'] as String,
      supplierId: map['supplier_id'] as int,
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String? ?? 'completed',
    );
  }

  @override
  List<Object?> get props => [
    id,
    noPurchase,
    tanggal,
    supplierId,
    total,
    status,
  ];
}
