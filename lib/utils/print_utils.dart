import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/work_order.dart';
import '../data/models/wo_item.dart';

Future<void> printBilling(WorkOrder wo, List<WoItem> items) async {
  final pdf = pw.Document();
  pdf.addPage(pw.Page(
    build: (pw.Context context) => pw.Column(
      children: [
        pw.Text('BENGKEL ABC', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.Divider(),
        pw.Text('No WO: ${wo.noWo}   Tanggal: ${wo.tanggal}'),
        pw.Text('Kendaraan: ${wo.platNomor} - ${wo.merk}'),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          data: [
            ['Item', 'Qty', 'Harga', 'Subtotal'],
            ...items.map((e) => [e.namaItem, e.qty.toString(), e.harga.toStringAsFixed(0), e.subtotal.toStringAsFixed(0)]),
          ],
        ),
        pw.Divider(),
        pw.Text('TOTAL: Rp ${wo.total.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 20)),
        pw.Text('Terima kasih!'),
      ],
    ),
  ));
  await Printing.layoutPdf(onLayout: (format) => pdf.save());
}