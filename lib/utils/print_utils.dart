import 'package:bengkel/data/models/wo_item.dart';
import 'package:bengkel/data/models/work_order.dart';
import 'package:bengkel/utils/number_format.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> printWorkOrderReceipt(WorkOrder wo, List<WoItem> items) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header Kwitansi
          pw.Center(
            child: pw.Text(
              'KWITANSI RESMI',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Center(
            child: pw.Text('BENGKEL ABC', style: pw.TextStyle(fontSize: 14)),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text('No WO: ${wo.noWo} | Tanggal: ${wo.tanggal}'),
          ),
          pw.Divider(height: 20),

          // Info Pelanggan & Kendaraan
          pw.Text('Nama Pelanggan: ${wo.namaCustomer ?? "-"}'),
          pw.Text(
            'Kendaraan: ${wo.platNomor ?? "-"} - ${wo.merk ?? ""} ${wo.tipe ?? ""}',
          ),
          pw.SizedBox(height: 16),

          // Tabel Item dengan Diskon
          pw.TableHelper.fromTextArray(
            headers: [
              'Item',
              'Qty',
              'Harga',
              'Disc %',
              'Harga Setelah Disc',
              'Subtotal',
            ],
            data: items.map((item) {
              final discPercent = item.discountPercent;
              final harga = item.harga;
              final qty = item.qty;
              final hargaAfterDisc = harga * (1 - (discPercent ?? 0.0) / 100);
              final subtotal = qty * hargaAfterDisc;

              return [
                item.namaItem,
                qty.toString(),
                formatCurrency(harga),
                '${discPercent?.toStringAsFixed(1)}%',
                formatCurrency(hargaAfterDisc),
                formatCurrency(subtotal),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.center,
            headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey200),
          ),

          pw.SizedBox(height: 20),

          // Total Akhir
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Total Sebelum Diskon: Rp ${nf.format(wo.total)}'),
                pw.Text(
                  'TOTAL YANG HARUS DIBAYAR: Rp ${nf.format(wo.total)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Text(
              'Terima kasih telah menggunakan jasa kami!',
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
      ),
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
    name: 'Kwitansi_WO_${wo.noWo}.pdf',
  );
}
