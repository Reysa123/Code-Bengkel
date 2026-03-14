import 'dart:typed_data';

import 'package:bengkel/core/constants/app_constants.dart';
import 'package:bengkel/utils/terbilang.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';

import '../data/models/wo_item.dart';
import '../data/models/work_order.dart';
import 'number_format.dart';

Future<Uint8List> generateReceiptPdf({
  required WorkOrder workOrder,
  required List<WoItem> items,
  required double grandTotalBeforeDisc,
  required double grandTotalAfterDisc,
  String? cashierName,
}) async {
  final pdf = pw.Document();

  final font = pw.Font.helvetica();
  final boldFont = pw.Font.helveticaBold(); // better contrast for totals
  final logo = await rootBundle.load(AppConstants.logoPath);
  final dateFormat = DateFormat('dd MMM yyyy');
  final tanggal = dateFormat.format(
    DateTime.tryParse(workOrder.tanggal) ?? DateTime.now(),
  );

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 28,
      ), // tighter margins
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header (compact) ──
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Image(
                    pw.MemoryImage((logo).buffer.asUint8List()),
                    width: 80,
                    height: 80,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    AppConstants.companyName,
                    style: pw.TextStyle(font: boldFont, fontSize: 15),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    AppConstants.companyAddress,
                    style: pw.TextStyle(fontSize: 9, font: font),
                  ),
                  pw.Text(
                    'Telp/WA: ${AppConstants.companyPhone}',
                    style: pw.TextStyle(fontSize: 9, font: font),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 1.2),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // ── WO & Customer Info ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Kwitansi',
                      style: pw.TextStyle(
                        fontSize: 11,

                        fontWeight: pw.FontWeight.bold,
                        font: font,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'No. WO: ${workOrder.noWo}',
                      style: pw.TextStyle(fontSize: 10, font: font),
                    ),
                    pw.Text(
                      'Tanggal: $tanggal',
                      style: pw.TextStyle(fontSize: 10, font: font),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Pelanggan',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: font,
                      ),
                    ),
                    pw.Text(
                      workOrder.namaCustomer ?? "-",
                      style: pw.TextStyle(fontSize: 10, font: font),
                    ),
                    pw.Text(
                      workOrder.platNomor ?? "-",
                      style: pw.TextStyle(fontSize: 10, font: font),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 14),

            // ── Compact Table ──
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              columnWidths: {
                0: pw.FlexColumnWidth(3.2), // Nama item
                1: pw.FixedColumnWidth(36), // Qty
                2: pw.FixedColumnWidth(68), // Harga satuan
                3: pw.FixedColumnWidth(48), // Disc %
                4: pw.FixedColumnWidth(80), // Subtotal akhir
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildCompactCell('Item', font, isHeader: true),
                    _buildCompactCell(
                      'Qty',
                      font,
                      isHeader: true,
                      align: pw.TextAlign.center,
                    ),
                    _buildCompactCell(
                      'Harga',
                      font,
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                    _buildCompactCell(
                      'Disc',
                      font,
                      isHeader: true,
                      align: pw.TextAlign.center,
                    ),
                    _buildCompactCell(
                      'Total',
                      font,
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
                // Item rows
                ...items.map((item) {
                  final discP = item.discountPercent ?? 0.0;
                  final discAmt = (item.harga * discP / 100) * item.qty;
                  final finalSub = item.subtotal - discAmt;

                  return pw.TableRow(
                    children: [
                      _buildCompactCell(
                        item.namaItem.trim(),
                        font,
                        fontSize: 9.5,
                      ),
                      _buildCompactCell(
                        '${item.qty}',
                        font,
                        align: pw.TextAlign.center,
                      ),
                      _buildCompactCell(
                        formatCurrency(item.harga),
                        font,
                        align: pw.TextAlign.right,
                      ),
                      _buildCompactCell(
                        discP > 0 ? '${discP.toStringAsFixed(1)}%' : '-',
                        font,
                        align: pw.TextAlign.center,
                      ),
                      _buildCompactCell(
                        formatCurrency(finalSub),
                        font,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 16),

            // ── Totals (right-aligned, compact) ──
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 220, // narrower
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildCompactSummary(
                      'Total sebelum disc',
                      font,
                      grandTotalBeforeDisc,
                      fontSize: 10,
                    ),
                    if ((grandTotalBeforeDisc - grandTotalAfterDisc).abs() >
                        0.5)
                      _buildCompactSummary(
                        'Diskon',
                        font,
                        grandTotalBeforeDisc - grandTotalAfterDisc,
                        isDiscount: true,
                        fontSize: 10,
                      ),
                    pw.Divider(height: 10, thickness: 1),
                    _buildCompactSummary(
                      'TOTAL BAYAR',
                      font,
                      grandTotalAfterDisc,
                      bold: true,
                      large: true,
                      fontSize: 12.5,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(
                TerbilangID(number: grandTotalAfterDisc).result,
                style: pw.TextStyle(
                  font: font,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            pw.Spacer(),

            // ── Footer (minimal) ──
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Terima kasih atas kunjungan Anda',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      font: font,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  if (cashierName != null)
                    pw.Text(
                      'Kasir: $cashierName',
                      style: pw.TextStyle(fontSize: 9, font: font),
                    ),
                ],
              ),
            ),
            pw.Spacer(),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

// ── Helper: smaller padding, smaller font ──
pw.Widget _buildCompactCell(
  String text,
  Font font, {
  bool isHeader = false,
  pw.TextAlign align = pw.TextAlign.left,

  double fontSize = 10,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(
      horizontal: 6,
      vertical: 5,
    ), // very tight
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: fontSize,
        font: font,
        fontWeight: isHeader ? pw.FontWeight.bold : null,
      ),
    ),
  );
}

pw.Widget _buildCompactSummary(
  String label,
  Font font,
  double value, {
  bool bold = false,
  bool large = false,
  bool isDiscount = false,
  double fontSize = 10.5,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: large ? fontSize + 1.5 : fontSize,
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
        ),
        pw.Text(
          formatCurrencyWithSymbol(value),
          style: pw.TextStyle(
            font: font,
            fontSize: large ? fontSize + 2 : fontSize,
            fontWeight: bold ? pw.FontWeight.bold : null,
            color: isDiscount ? PdfColors.red800 : null,
          ),
        ),
      ],
    ),
  );
}
