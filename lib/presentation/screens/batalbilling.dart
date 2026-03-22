// ---------------------- Halaman 1: Cari WO yang akan dibatalkan finish ----------------------
import 'package:bengkel/data/repositories/work_order_repository.dart';
import 'package:flutter/material.dart';

class UndoFinishWorkOrderSearchPage extends StatefulWidget {
  const UndoFinishWorkOrderSearchPage({super.key});

  @override
  State<UndoFinishWorkOrderSearchPage> createState() =>
      _UndoFinishWorkOrderSearchPageState();
}

class _UndoFinishWorkOrderSearchPageState
    extends State<UndoFinishWorkOrderSearchPage> {
  final _woController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _searchAndNavigate() async {
    final woIdStr = _woController.text.trim();
    if (woIdStr.isEmpty) {
      setState(() => _errorText = 'Masukkan nomor WO');
      return;
    }

    final woId = woIdStr;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final woData = await _fetchWorkOrderSummary(woId);

      if (!mounted) return;

      if (woData == null) {
        setState(() => _errorText = 'Work order tidak ditemukan');
        return;
      }

      if (woData['status'] != 'finished') {
        setState(
          () => _errorText =
              'Status WO bukan "finished". Tidak dapat dibatalkan.',
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UndoFinishWorkOrderConfirmPage(
            woId: woId,
            platNomor: woData['plat_nomor'] ?? '-',
            namaPelanggan: woData['nama_customer'] ?? '-',
            tanggal: woData['tanggal'] ?? '-',
            paid: woData['paid'] as double? ?? 0.0,
            totalPendapatan: woData['total_pendapatan'] as double? ?? 0.0,
            totalHppPart: woData['total_hpp_part'] as double? ?? 0.0,
            totalDiskon: woData['total_diskon'] as double? ?? 0.0,
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorText = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Ambil data ringkasan yang diperlukan
  Future<Map<String, dynamic>?> _fetchWorkOrderSummary(String woId) async {
    final woResult = await WorkOrderRepository().getAllByWoId(woId);

    if (woResult.isEmpty) return null;
    final wo = woResult.first;

    // Hitung ulang ringkasan (mirip logika di finishWorkOrderAndPrint)

    double pendapatanJasa = 0;
    double pendapatanPart = 0;
    double hppPart = 0;

    for (var item in woResult) {
      final qty = item['qty_item'] as num? ?? 0;
      final hj = item['harga_jual'] as num? ?? 0;
      final hb = item['harga_beli'] as num? ?? 0;
      final type = item['type_item'] as String?;

      if (type == 'part') {
        hppPart += hb * qty;
        pendapatanPart += hj * qty;
      } else if (type == 'service') {
        pendapatanJasa += hj * qty;
      }
    }

    final totalPendapatan = pendapatanJasa + pendapatanPart;
    final paid = wo['paid'] as double? ?? 0.0;
    final totalDiskon = totalPendapatan - paid;

    return {
      ...wo,
      'total_pendapatan': totalPendapatan,
      'total_hpp_part': hppPart,
      'total_diskon': totalDiskon,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batalkan Penyelesaian WO')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'Masukkan Nomor Work Order',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _woController,
              decoration: InputDecoration(
                labelText: 'No. WO',
                border: const OutlineInputBorder(),
                errorText: _errorText,
                prefixIcon: const Icon(Icons.work),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _searchAndNavigate(),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoading ? 'Memeriksa...' : 'Cari & Lanjut'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: _isLoading ? null : _searchAndNavigate,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _woController.dispose();
    super.dispose();
  }
}

// ---------------------- Halaman 2: Konfirmasi Pembatalan Penyelesaian ----------------------
class UndoFinishWorkOrderConfirmPage extends StatefulWidget {
  final String woId;
  final String platNomor;
  final String namaPelanggan;
  final String tanggal;
  final double paid;
  final double totalPendapatan;
  final double totalHppPart;
  final double totalDiskon;

  const UndoFinishWorkOrderConfirmPage({
    super.key,
    required this.woId,
    required this.platNomor,
    required this.namaPelanggan,
    required this.tanggal,
    required this.paid,
    required this.totalPendapatan,
    required this.totalHppPart,
    required this.totalDiskon,
  });

  @override
  State<UndoFinishWorkOrderConfirmPage> createState() =>
      _UndoFinishWorkOrderConfirmPageState();
}

class _UndoFinishWorkOrderConfirmPageState
    extends State<UndoFinishWorkOrderConfirmPage> {
  final _alasanController = TextEditingController();
  bool _isProcessing = false;
  String? _error;

  Future<void> _undoFinish() async {
    final alasan = _alasanController.text.trim();
    if (alasan.isEmpty) {
      setState(() => _error = 'Alasan wajib diisi');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    final success = await WorkOrderRepository().undoFinishWorkOrder(
      woId: widget.woId,
      alasan: alasan,
      dibuatOleh: 'admin', // ← ganti dengan user login
    );

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Penyelesaian WO ${widget.woId} berhasil dibatalkan'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _error = 'Gagal membatalkan penyelesaian. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Batal Selesai')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Work Order',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    _infoRow('No. WO', widget.woId.toString()),
                    _infoRow('Pelanggan', widget.namaPelanggan),
                    _infoRow('No. Polisi', widget.platNomor),
                    _infoRow('Tanggal', widget.tanggal),
                    _infoRow(
                      'Jumlah Dibayar',
                      'Rp ${widget.paid.toStringAsFixed(0)}',
                      isMoney: true,
                    ),
                    const Divider(),
                    _infoRow(
                      'Total Pendapatan',
                      'Rp ${widget.totalPendapatan.toStringAsFixed(0)}',
                      isMoney: true,
                    ),
                    _infoRow(
                      'Diskon diberikan',
                      'Rp ${widget.totalDiskon.toStringAsFixed(0)}',
                      isMoney: true,
                    ),
                    _infoRow(
                      'HPP Part',
                      'Rp ${widget.totalHppPart.toStringAsFixed(0)}',
                      isMoney: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'Alasan Pembatalan Penyelesaian',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alasanController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Masukkan alasan pembatalan penyelesaian WO ini...',
                errorText: _error,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 32),
            Center(
              child: FilledButton.icon(
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.undo),
                label: Text(
                  _isProcessing ? 'Memproses...' : 'Batalkan Penyelesaian WO',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: _isProcessing ? null : _undoFinish,
              ),
            ),

            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Tindakan ini akan mengembalikan status WO dan menghapus semua jurnal terkait invoice.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isMoney = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isMoney ? Colors.green[800] : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }
}
