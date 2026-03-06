import 'package:equatable/equatable.dart';

class WoItem extends Equatable {
  final int? id;
  final int? woId;
  final String type; // 'service' atau 'part'
  final int itemId;
  final String namaItem;
  final int qty;
  final double harga;
  final double? discountPercent; // diskon % per item (0–100)
  final double? discountAmount;
  final double subtotal;

  const WoItem({
    this.id,
    this.woId = 0,
    required this.type,
    required this.itemId,
    required this.namaItem,
    required this.qty,
    required this.harga,
    this.discountPercent = 0.0,
    this.discountAmount,
    required this.subtotal,
  });
  double get finalPrice {
    final disc = (harga * (discountPercent ?? 0) / 100);
    return harga - disc;
  }

  double get finalSubtotal => qty * finalPrice;
  WoItem copyWith({
    int? id,
    int? woId,
    String? type,
    int? itemId,
    String? namaItem,
    int? qty,
    double? harga,
    double? subtotal,
    double? discountPercent,
  }) {
    return WoItem(
      id: id ?? this.id,
      woId: woId ?? this.woId,
      type: type ?? this.type,
      itemId: itemId ?? this.itemId,
      namaItem: namaItem ?? this.namaItem,
      qty: qty ?? this.qty,
      harga: harga ?? this.harga,
      subtotal: subtotal ?? this.subtotal,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'wo_id': woId,
    'type': type,
    'item_id': itemId,
    'nama_item': namaItem,
    'qty': qty,
    'harga': harga,
    'discount_percent': discountPercent,
    'subtotal': subtotal,
  };

  factory WoItem.fromMap(Map<String, dynamic> map) => WoItem(
    id: map['id'],
    woId: map['wo_id'],
    type: map['type'],
    itemId: map['item_id'],
    namaItem: map['nama_item'],
    qty: map['qty'],
    harga: map['harga'],
    subtotal: map['subtotal'],
  );

  @override
  List<Object?> get props => [
    id,
    woId,
    type,
    itemId,
    namaItem,
    qty,
    harga,
    discountPercent,
    subtotal,
  ];
}
