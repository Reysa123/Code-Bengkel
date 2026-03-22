import 'package:bengkel/data/repositories/work_order_repository.dart';
import 'package:bengkel/utils/number_format.dart';
import 'package:flutter/material.dart';

// ---------------------- Halaman Pertama: Search WO ----------------------
class CancelPaymentSearchPage extends StatefulWidget {
  const CancelPaymentSearchPage({super.key});

  @override
  State<CancelPaymentSearchPage> createState() =>
      _CancelPaymentSearchPageState();
}

class _CancelPaymentSearchPageState extends State<CancelPaymentSearchPage> {
  final _woController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _searchAndNavigate() async {
    final woId = _woController.text.trim();
    if (woId.isEmpty) {
      setState(() => _errorText = 'Masukkan nomor WO');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      // Panggil fungsi yang sudah kamu buat
      final woData = await _fetchWorkOrderData(woId);

      if (!mounted) return;

      if (woData == null) {
        setState(() => _errorText = 'Work order tidak ditemukan');
        return;
      }

      if (woData['status'] != 'paid') {
        setState(
          () => _errorText = 'WO ini belum dibayar atau sudah dibatalkan',
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CancelPaymentConfirmPage(
            woId: woId,
            namaPelanggan: woData['nama_customer'] ?? '-',
            nopol: woData['plat_nomor'] ?? '-',
            jumlahBayar: woData['paid'] as double? ?? 0.0,
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorText = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Contoh fungsi fetch data WO (sesuaikan dengan DB helper kamu)
  Future<Map<String, dynamic>?> _fetchWorkOrderData(String woId) async {
    final result = await WorkOrderRepository().getAllByWoId(woId);

    if (result.isEmpty) return null;

    return result.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batalkan Pembayaran')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
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
                prefixIcon: const Icon(Icons.receipt_long),
              ),
              textCapitalization: TextCapitalization.characters,
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

// ---------------------- Halaman Kedua: Konfirmasi Pembatalan ----------------------
class CancelPaymentConfirmPage extends StatefulWidget {
  final String woId;
  final String namaPelanggan;
  final String nopol;
  final double jumlahBayar;

  const CancelPaymentConfirmPage({
    super.key,
    required this.woId,
    required this.namaPelanggan,
    required this.nopol,
    required this.jumlahBayar,
  });

  @override
  State<CancelPaymentConfirmPage> createState() =>
      _CancelPaymentConfirmPageState();
}

class _CancelPaymentConfirmPageState extends State<CancelPaymentConfirmPage> {
  final _alasanController = TextEditingController();
  bool _isProcessing = false;
  String? _error;

  Future<void> _cancelPayment() async {
    final alasan = _alasanController.text.trim();
    if (alasan.isEmpty) {
      setState(() => _error = 'Alasan pembatalan wajib diisi');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    final success = await WorkOrderRepository().cancelPayment(
      woId: widget.woId,
      alasan: alasan,
      dibuatOleh: "admin", // ← ganti dengan user yang sedang login
    );

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembayaran WO ${widget.woId} berhasil dibatalkan'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // kembali + kasih sinyal sukses
    } else {
      setState(() {
        _error = 'Gagal membatalkan pembayaran. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pembatalan')),
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
                    _infoRow('No. WO', widget.woId),
                    _infoRow('Pelanggan', widget.namaPelanggan),
                    _infoRow('No. Polisi', widget.nopol),
                    _infoRow(
                      'Jumlah Pembayaran',
                      'Rp ${nf.format(widget.jumlahBayar)}',
                      isMoney: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Alasan Pembatalan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alasanController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Masukkan alasan pembatalan pembayaran...',
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
                    : const Icon(Icons.cancel),
                label: Text(
                  _isProcessing ? 'Memproses...' : 'Batalkan Pembayaran',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: _isProcessing ? null : _cancelPayment,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Tindakan ini akan mengembalikan status WO dan menghapus jurnal pembayaran.',
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
