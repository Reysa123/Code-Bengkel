import 'package:bengkel/core/constants/app_constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models/work_order.dart';
import '../data/models/wo_item.dart';
import '../utils/number_format.dart'; // nf dari sebelumnya

Future<void> printWorkOrderInvoice(WorkOrder wo, List<WoItem> items) async {
  final pdf = pw.Document();
final name = await AppConstants.companyName();
  final add = await AppConstants.companyAddress();
  final phone = await AppConstants.companyPhone();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INVOICE / NOTA WO',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text('No: ${wo.noWo}'),
                  pw.Text('Tanggal: ${wo.tanggal}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Info Kendaraan & Customer
          pw.Text(
            'Kendaraan: ${wo.platNomor ?? "-"} - ${wo.merk ?? ""} ${wo.tipe ?? ""}',
          ),
          pw.Text('Customer: ${wo.namaCustomer ?? "-"}'),
          pw.SizedBox(height: 20),

          // Tabel Item
          pw.TableHelper.fromTextArray(
            headers: ['Item', 'Qty', 'Harga Satuan', 'Subtotal'],
            data: items
                .map(
                  (item) => [
                    item.namaItem,
                    item.qty.toString(),
                    nf.format(item.harga),
                    nf.format(item.subtotal),
                  ],
                )
                .toList(),
            border: null,
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),

          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // Total
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'TOTAL :  ',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Rp ${nf.format(wo.total)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 40),
          pw.Center(
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
    onLayout: (format) async => pdf.save(),
    name: 'WO_${wo.noWo}_Invoice.pdf',
  );
}
