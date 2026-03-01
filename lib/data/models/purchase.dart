import 'package:equatable/equatable.dart';

class Purchase extends Equatable {
  final int? id;
  final String noPurchase;
  final String tanggal;
  final int supplierId;
  final double total;
  final String status;

  const Purchase({
    this.id,
    required this.noPurchase,
    required this.tanggal,
    required this.supplierId,
    required this.total,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'no_purchase': noPurchase,
        'tanggal': tanggal,
        'supplier_id': supplierId,
        'total': total,
        'status': status,
      };

  factory Purchase.fromMap(Map<String, dynamic> map) => Purchase(
        id: map['id'],
        noPurchase: map['no_purchase'],
        tanggal: map['tanggal'],
        supplierId: map['supplier_id'],
        total: map['total'],
        status: map['status'],
      );

  @override
  List<Object?> get props => [id, noPurchase];
}

class PurchaseItem {
  int? id;
  int? purchaseId;
  final int partId;
  final int qty;
  final double hargaBeli;

  PurchaseItem({
    this.id,
    this.purchaseId,
    required this.partId,
    required this.qty,
    required this.hargaBeli,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'purchase_id': purchaseId,
        'part_id': partId,
        'qty': qty,
        'harga_beli': hargaBeli,
      };
}