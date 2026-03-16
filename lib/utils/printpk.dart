
import 'package:bengkel/core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../utils/number_format.dart'; // nf = NumberFormat('#,###', 'id_ID')

// ==================== PDF GENERATOR ====================
Future<void> generatePKPDF(List<Map<String, dynamic>> workOrders) async {
  final pdf = pw.Document();
  pw.TextStyle style = const pw.TextStyle(fontSize: 8);
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) => [
        // Header Bengkel
        pw.Text(
          AppConstants.companyName,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          AppConstants.companyAddress,
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          'Telp: ${AppConstants.companyPhone}',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Perintah Work Order',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 20),

        // Info Kendaraan & Customer (dari WO pertama)
        if (workOrders.isNotEmpty) ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text('No. Chasis', style: style),
                      ),
                      pw.SizedBox(width: 10, child: pw.Text(':', style: style)),
                      pw.SizedBox(
                        width: 200,
                        child: pw.Text(
                          workOrders.first['wo']['nora'] ?? '-',
                          style: style,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text('Plat Nomor', style: style),
                      ),
                      pw.SizedBox(width: 10, child: pw.Text(':', style: style)),
                      pw.SizedBox(
                        width: 200,
                        child: pw.Text(
                          workOrders.first['wo']['plat_nomor'] ?? '-',
                          style: style,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text('Merk & Tipe', style: style),
                      ),
                      pw.SizedBox(width: 10, child: pw.Text(':', style: style)),
                      pw.SizedBox(
                        width: 200,
                        child: pw.Text(
                          '${workOrders.first['wo']['merk'] ?? ''} / ${workOrders.first['wo']['tipe'] ?? ''}',
                          style: style,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text('Tahun', style: style),
                      ),
                      pw.SizedBox(width: 10, child: pw.Text(':', style: style)),
                      pw.SizedBox(
                        width: 200,
                        child: pw.Text(
                          workOrders.first['wo']['tahun'] ?? '-',
                          style: style,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text('Nama Pelanggan', style: style),
                      ),
                      pw.SizedBox(width: 10, child: pw.Text(':', style: style)),
                      pw.SizedBox(
                        width: 200,
                        child: pw.Text(
                          workOrders.first['wo']['nama_customer'] ?? '-',
                          style: style,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text('Alamat', style: style),
                      ),
                      pw.SizedBox(width: 10, child: pw.Text(':', style: style)),
                      pw.SizedBox(
                        width: 200,
                        child: pw.Text(
                          workOrders.first['wo']['alamat'] ?? '-',
                          style: style,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text('No. HP', style: style),
                      ),
                      pw.SizedBox(width: 10, child: pw.Text(':', style: style)),
                      pw.SizedBox(
                        width: 200,
                        child: pw.Text(
                          workOrders.first['wo']['no_hp'] ?? '-',
                          style: style,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text('KM', style: style),
                      ),
                      pw.SizedBox(width: 10, child: pw.Text(':', style: style)),
                      pw.SizedBox(
                        width: 200,
                        child: pw.Text(
                          workOrders.first['wo']['kmTerakhir'] ?? '-',
                          style: style,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
        ],

        // Daftar Work Order
        pw.Text(
          'Daftar Work Order',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),

        ...workOrders.map((data) {
          final wo = data['wo'];
          final items = data['items'] as List<Map<String, dynamic>>;
          final total = items.fold<double>(
            0.0,
            (sum, item) =>
                sum + (item['subtotal_item'] as num? ?? 0).toDouble(),
          );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'No WO: ${wo['no_wo'] ?? '-'} | Tanggal: ${wo['tanggal'] ?? '-'}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Status: ${wo['status']?.toUpperCase() ?? '-'} | Mekanik: ${wo['nama_mekanik'] ?? '-'}',
              ),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                headers: ['No', 'Item', 'Qty', 'Harga', 'Subtotal'],
                data: items.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  return [
                    '${i + 1}',
                    item['nama_item'] ?? '-',
                    '${item['qty_item'] ?? 1}x',
                    'Rp ${nf.format((item['harga_item'] as num?)?.toDouble() ?? 0)}',
                    'Rp ${nf.format((item['subtotal_item'] as num?)?.toDouble() ?? 0)}',
                  ];
                }).toList(),
                border: null,
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
              ),

              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'TOTAL: Rp ${nf.format(total)}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
            ],
          );
        }),

        pw.Footer(
          trailing: pw.Text(
            'Dicetak pada: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'PK ${workOrders.first['wo']['no_wo']}.pdf',
  );
}
