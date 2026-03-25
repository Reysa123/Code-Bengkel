class ExternalOrder {
  final int? id;
  final String? tanggal;
  final int? woId;
  final String? type;
  final String? deskripsi;
  final double? beli;
  final double? jual;
  final double? qty;
  final String? vendor;
  final String? status;
  final String? nospk;
  bool? isSelect = false;
  ExternalOrder({
    this.id,
    this.tanggal,
    this.woId,
    this.type,
    this.deskripsi,
    this.beli,
    this.jual,
    this.qty,
    this.vendor,
    this.status,
    this.nospk,
    this.isSelect,
  });

  factory ExternalOrder.fromMap(Map<String, dynamic> map) => ExternalOrder(
    id: map['id'] as int?,
    tanggal: map['tanggal'] as String?,
    woId: map['wo_id'] as int?,
    type: map['type'] as String?,
    deskripsi: map['deskripsi'] as String?,
    beli: (map['beli'] as num?)?.toDouble(),
    jual: (map['jual'] as num?)?.toDouble(),
    qty: (map['qty'] as num?)?.toDouble(),
    vendor: map['vendor'] as String?,
    status: map['status'] as String,
    nospk: map['nospk'] as String,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'tanggal': tanggal,
    'wo_id': woId,
    'type': type,
    'deskripsi': deskripsi,
    'beli': beli,
    'jual': jual,
    'qty': qty,
    'vendor': vendor,
    'status': status,
    'nospk': nospk,
  };
}
