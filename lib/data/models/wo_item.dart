import 'package:equatable/equatable.dart';

class WoItem extends Equatable {
  final int? id;
  final int? woId;
  final String type; // 'service' atau 'part'
  final int itemId;
  final String namaItem;
  final int qty;
  final double harga;
  final double subtotal;

   const WoItem({
    this.id,
    this.woId = 0,
    required this.type,
    required this.itemId,
    required this.namaItem,
    required this.qty,
    required this.harga,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'wo_id': woId,
    'type': type,
    'item_id': itemId,
    'nama_item': namaItem,
    'qty': qty,
    'harga': harga,
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
  List<Object?> get props => [id, woId, type, itemId, namaItem, qty];
}
