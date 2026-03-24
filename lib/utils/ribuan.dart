import 'package:bengkel/utils/number_format.dart';
import 'package:flutter/services.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 1. Hitung berapa banyak karakter non-digit (titik) sebelum kursor pada teks lama

    // 2. Ambil angka murni (tanpa titik)
    String newValueText = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    final double? doubleValue = double.tryParse(newValueText);
    if (doubleValue == null) return oldValue;

    // 3. Format ulang ke ribuan (Indonesia)
    String newText = nf.format(doubleValue);

    // 4. Hitung posisi kursor baru yang tepat
    // Rumus: Posisi kursor baru = (Posisi kursor lama - jumlah titik lama) + jumlah titik baru

    // Sesuaikan index kursor agar tidak offset saat ada penambahan/pengurangan titik

    // Hitung offset manual untuk akurasi saat kursor di tengah
    int editOffset = newText.length - oldValue.text.length;
    int newSelectionIndex = oldValue.selection.end + editOffset;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newSelectionIndex.clamp(0, newText.length),
      ),
    );
  }
}
