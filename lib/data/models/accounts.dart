class Account {
  final int? id;
  final String code;
  final String name;
  final String type; // asset, liability, equity, revenue, expense
  final String normalBalance; // debit, kredit

  Account({
    this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.normalBalance,
  });

  // Konversi dari Map (Database) ke Objek Dart
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      type: map['type'],
      normalBalance: map['normal_balance'],
    );
  }

  // Konversi dari Objek Dart ke Map (untuk Insert/Update Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type,
      'normal_balance': normalBalance,
    };
  }

  // Memudahkan debugging saat print(account)
  @override
  String toString() {
    return 'Account($code - $name | $type)';
  }
}
