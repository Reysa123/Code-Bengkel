import 'package:intl/intl.dart';

final NumberFormat nf = NumberFormat('#,###', 'id_ID');

String formatCurrency(double value) {
  return nf.format(value);
}

String formatCurrencyWithSymbol(double value) {
  return 'Rp ${nf.format(value)}';
}