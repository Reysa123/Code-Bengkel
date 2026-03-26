import 'package:bengkel/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/repositories/work_order_repository.dart';
import '../../utils/number_format.dart'; // nf = NumberFormat('#,###', 'id_ID')

class HistoryWorkOrderScreen extends StatefulWidget {
  final String searchKey; // nora atau plat_nomor yang dicari

  const HistoryWorkOrderScreen({super.key, required this.searchKey});

  @override
  State<HistoryWorkOrderScreen> createState() => _HistoryWorkOrderScreenState();
}

class _HistoryWorkOrderScreenState extends State<HistoryWorkOrderScreen> {
  final WorkOrderRepository _repo = WorkOrderRepository();
  List<Map<String, dynamic>> _workOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final df = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _repo.getWoIdByNora(widget.searchKey);

      // Group by no_wo agar setiap WO punya list itemnya sendiri
      final grouped = <String, Map<String, dynamic>>{};
      for (var row in result) {
        final noWo = row['no_wo'] as String;
        if (!grouped.containsKey(noWo)) {
          grouped[noWo] = {'wo': row, 'items': <Map<String, dynamic>>[]};
        }
        if (row['nama_item'] != null) {
          grouped[noWo]!['items'].add(row);
        }
      }

      setState(() {
        _workOrders = grouped.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'on_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'paid':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _exportToPDF() async {
    if (_workOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor')),
      );
      return;
    }

    final pdf = pw.Document();
    final compName = await AppConstants.companyName();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  compName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'RIWAYAT KENDARAAN',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Info Kendaraan & Customer (ambil dari WO pertama)
          if (_workOrders.isNotEmpty) ...[
            pw.Text(
              'Info Kendaraan & Pelanggan',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['', '', '', ''],
              data: [
                [
                  'No.Chassis',
                  _workOrders.first['wo']['nora'] ?? '-',
                  'Plat Nomor',
                  _workOrders.first['wo']['plat_nomor'] ?? '-',
                ],
                [
                  'Merk & Tipe',
                  '${_workOrders.first['wo']['merk'] ?? ''} - ${_workOrders.first['wo']['tipe'] ?? ''}',

                  'Tahun',
                  _workOrders.first['wo']['tahun'] ?? '-',
                ],
                [
                  'Warna',
                  _workOrders.first['wo']['warna'] ?? '-',
                  'KM Terakhir',
                  '${_workOrders.first['wo']['kmTerakhir'] ?? '-'} km',
                ],
                [
                  'Nama Customer',
                  _workOrders.first['wo']['nama_customer'] ?? '-',
                  'Alamat',
                  _workOrders.first['wo']['alamat'] ?? '-',
                ],
                // ['No HP', _workOrders.first['wo']['no_hp'] ?? '-'],
              ],
              border: null,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellHeight: 25,
            ),
            pw.SizedBox(height: 20),
          ],

          pw.Text(
            'Daftar Work Order',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          ..._workOrders.map((data) {
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
                  'No WO: ${wo['no_wo'] ?? '-'}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('Tanggal: ${wo['tanggal'] ?? '-'}'),
                pw.Text('Status: ${wo['status']?.toUpperCase() ?? '-'}'),
                pw.Text('Mekanik: ${wo['nama_mekanik'] ?? '-'}'),
                pw.SizedBox(height: 8),

                pw.TableHelper.fromTextArray(
                  headers: ['Item', 'Qty', 'Harga', 'Subtotal'],
                  data: items
                      .map(
                        (item) => [
                          item['nama_item'] ?? '-',
                          '${item['qty_item'] ?? 1}x',
                          'Rp ${nf.format((item['harga_item'] as num?)?.toDouble() ?? 0)}',
                          'Rp ${nf.format((item['subtotal_item'] as num?)?.toDouble() ?? 0)}',
                        ],
                      )
                      .toList(),
                  border: null,
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellHeight: 25,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                ),

                pw.SizedBox(height: 8),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'TOTAL: Rp ${nf.format(total)}',
                    style: pw.TextStyle(
                      fontSize: 12,
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
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );

    // Preview & Print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Riwayat_WO_${widget.searchKey}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Kendaraan'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _workOrders.isEmpty ? null : _exportToPDF,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _workOrders.isEmpty
          ? const Center(
              child: Text(
                'Tidak ditemukan riwayat',
                style: TextStyle(fontSize: 18),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 12,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Customer       : ${_workOrders.first['wo']['nama_customer'] ?? '-'}',
                                ),
                              ),
                              Flexible(
                                flex: 1,
                                child: Text(
                                  'Kendaraan            : ${_workOrders.first['wo']['plat_nomor'] ?? '-'} - ${_workOrders.first['wo']['merk'] ?? ''} ${_workOrders.first['wo']['tipe'] ?? ''}',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            spacing: 12,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Alamat           : ${_workOrders.first['wo']['alamat'] ?? '-'}',
                                ),
                              ),
                              Flexible(
                                flex: 1,
                                child: Text(
                                  'No. Chasis/Tahun : ${_workOrders.first['wo']['nora'] ?? '-'}/${_workOrders.first['wo']['tahun'] ?? '-'}',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            spacing: 12,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Telepon          : ${_workOrders.first['wo']['no_hp'] ?? '-'}',
                                ),
                              ),
                              Flexible(
                                flex: 1,
                                child: Text(
                                  'Warna                  : ${_workOrders.first['wo']['warna'] ?? '-'}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _workOrders.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final data = _workOrders[index];
                        final wo = data['wo'] as Map<String, dynamic>;
                        final items =
                            data['items'] as List<Map<String, dynamic>>;

                        final total = items.fold<double>(
                          0.0,
                          (sum, item) =>
                              sum +
                              (item['subtotal_item'] as num? ?? 0).toDouble(),
                        );

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(
                                wo['status'],
                              ).withAlpha(2),
                              child: Icon(
                                Icons.receipt_long,
                                color: _getStatusColor(wo['status']),
                              ),
                            ),
                            title: Text(
                              wo['no_wo'] as String? ?? 'No WO tidak tersedia',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Tanggal: ${wo['tanggal'] ?? '-'}'),
                                    // Text('Customer: ${wo['nama_customer'] ?? '-'}'),
                                    // Text(
                                    //   'Kendaraan: ${wo['plat_nomor'] ?? '-'} - ${wo['merk'] ?? ''} ${wo['tipe'] ?? ''}',
                                    // ),
                                    Text(
                                      'KM Terakhir: ${wo['kmTerakhir'] ?? '-'} km',
                                    ),
                                    Text(
                                      'Mekanik: ${wo['nama_mekanik'] ?? '-'}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                    wo['status']?.toUpperCase() ?? 'UNKNOWN',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: _getStatusColor(
                                    wo['status'],
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Detail Pekerjaan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...items
                                        .where(
                                          (v) => v['type_item'] == 'service',
                                        )
                                        .map((item) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    item['nama_item'] ?? '-',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    '${item['qty_item'] ?? 1}x',
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    'Rp ${nf.format((item['harga_item'] as num?)?.toDouble() ?? 0)}',
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    'Rp ${nf.format((item['subtotal_item'] as num?)?.toDouble() ?? 0)}',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                    const Text(
                                      'Detail Part',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...items
                                        .where((v) => v['type_item'] == 'part')
                                        .map((item) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    item['nama_item'] ?? '-',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    '${item['qty_item'] ?? 1}x',
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    'Rp ${nf.format((item['harga_item'] as num?)?.toDouble() ?? 0)}',
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    'Rp ${nf.format((item['subtotal_item'] as num?)?.toDouble() ?? 0)}',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'TOTAL :  ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Rp ${nf.format(total)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
