import 'package:equatable/equatable.dart';

class PurchaseItem extends Equatable {
  final int? id;
  final int purchaseId;
  final int partId;
  final String?
  partName; // ← ini opsional, bisa diisi saat join dengan tabel parts
  final int qty;
  final double hargaBeli;
  final double subtotal;

  const PurchaseItem({
    this.id,
    required this.purchaseId,
    required this.partId,
    this.partName,
    required this.qty,
    required this.hargaBeli,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'part_id': partId,
      'qty': qty,
      'harga_beli': hargaBeli,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'],
      purchaseId: map['purchase_id'] as int,
      partId: map['part_id'] as int,
      qty: map['qty'] as int,
      hargaBeli: (map['harga_beli'] as num).toDouble(),
      subtotal: (map['total'] as num).toDouble(),
    );
  }

  PurchaseItem copyWith({
    int? id,
    int? purchaseId,
    int? partId,
    int? qty,
    double? hargaBeli,
    double? subtotal,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      partId: partId ?? this.partId,
      qty: qty ?? this.qty,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  @override
  List<Object?> get props => [id, purchaseId, partId, qty, hargaBeli, subtotal];
}
