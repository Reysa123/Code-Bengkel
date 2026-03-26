import 'package:bengkel/core/constants/app_constants.dart';
import 'package:bengkel/utils/number_format.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models/purchase.dart';
import '../data/models/purchase_item.dart';
import '../data/models/part.dart'; // jika ingin tampilkan nama part

Future<void> printPurchaseNota(
  Purchase purchase,
  List<PurchaseItem> items,
  List<Part> allParts, // untuk lookup nama part
  String supplierName,
) async {
  final pdf = pw.Document();

  // Load font (opsional, agar lebih bagus di Android/iOS)
  // final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
  // final ttf = pw.Font.ttf(fontData);
  final name = await AppConstants.companyName();
  final add = await AppConstants.companyAddress();
  final phone = await AppConstants.companyPhone();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header Nota
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    name,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    add,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                   phone,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'NOTA PEMBELIAN',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'No: ${purchase.noPurchase}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Tanggal: ${purchase.tanggal}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Supplier
          pw.Text(
            'Supplier:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(supplierName),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.symmetric(vertical: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              'Total Pembelian: Rp ${formatCurrency(purchase.total)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
          ),
          pw.SizedBox(height: 20),

          // Tabel Item
          pw.TableHelper.fromTextArray(
            border: null,
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
            headerHeight: 30,
            cellHeight: 25,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            data: <List<String>>[
              ['Kode - Nama Part', 'Qty', 'Harga Beli', 'Subtotal'],
              ...items.map((item) {
                final part = allParts.firstWhere(
                  (p) => p.id == item.partId,
                  orElse: () => Part(
                    kode: '-',
                    nama: 'Part tidak ditemukan',
                    stok: 0,
                    hargaBeli: 0,
                    hargaJual: 0,
                  ),
                );
                return [
                  '${part.kode} - ${part.nama}',
                  item.qty.toString(),
                  formatCurrency(item.hargaBeli),
                  formatCurrency(item.subtotal),
                ];
              }),
            ],
          ),

          pw.SizedBox(height: 30),

          // Footer
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Terima kasih atas kepercayaan Anda!',
              style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
      ),
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'Nota_Pembelian_${purchase.noPurchase}.pdf',
  );
}
