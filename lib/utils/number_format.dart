import 'package:intl/intl.dart';

final NumberFormat nf = NumberFormat('#,###', 'id_ID');

String formatCurrency(double value) {
  return nf.format(value);
}

String formatCurrencyWithSymbol(double value) {
  return 'Rp ${nf.format(value)}';
}

String cleanNumber(String? text) {
  if (text == null || text.isEmpty) return '0';
  // Hapus semua karakter non-digit kecuali tanda minus dan titik desimal
  return text.replaceAll(RegExp(r'[^0-9.]'), '');
}
