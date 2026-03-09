// lib/presentation/screens/work_order_detail_screen.dart

import 'package:bengkel/utils/number_format.dart';
import 'package:bengkel/utils/print_work_order_invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/work_order.dart';
import '../../data/models/wo_item.dart';
import '../../data/repositories/work_order_repository.dart';
import '../../presentation/blocs/work_order_cubit.dart';
// fungsi printWorkOrderInvoice

class WorkOrderDetailScreen extends StatefulWidget {
  final WorkOrder workOrder;

  const WorkOrderDetailScreen({super.key, required this.workOrder});

  @override
  State<WorkOrderDetailScreen> createState() => _WorkOrderDetailScreenState();
}

class _WorkOrderDetailScreenState extends State<WorkOrderDetailScreen> {
  bool _isLoading = false;
  List<WoItem> _woItems = [];

  final WorkOrderRepository _repo = WorkOrderRepository();

  @override
  void initState() {
    super.initState();
    _loadWoItems();
  }

  Future<void> _loadWoItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _repo.getWoItems(
        int.parse(widget.workOrder.noWo),
        'pending',
      );
      setState(() {
        _woItems = items.where((v) => v.type == 'part').toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeAndPrint() async {
    setState(() => _isLoading = true);

    try {
      // 1. Cek stok cukup atau tidak
      final sufficient = await _repo.checkStockSufficient(
        int.parse(widget.workOrder.noWo),
      );
      if (!sufficient) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Stok Tidak Mencukupi',
              style: TextStyle(color: Colors.red),
            ),
            content: const Text(
              'Beberapa part yang digunakan di Work Order ini stoknya tidak mencukupi.\n\n'
              'Silakan tambah stok melalui menu Pembelian Part terlebih dahulu.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
        return;
      }

      // 2. Jika stok OK → complete WO & kurangi stok
      await _repo.cetakPartWorkOrder(
        int.parse(widget.workOrder.noWo),
        deductStock: true,
      );

      // 3. Refresh item dan list WO
      await _loadWoItems();
      if (mounted) {
        context.read<WorkOrderCubit>().loadAll();
      }

      // 4. Cetak nota
      await printWorkOrderInvoice(widget.workOrder, _woItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work Order selesai! Stok dikurangi & nota dicetak.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan WO: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail WO ${widget.workOrder.noWo}'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Info Utama
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                color: Colors.indigo,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Work Order: ${widget.workOrder.noWo}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          _buildDetailRow(
                            Icons.calendar_today,
                            'Tanggal',
                            widget.workOrder.tanggal,
                          ),
                          _buildDetailRow(
                            Icons.directions_car,
                            'Kendaraan',
                            widget.workOrder.platNomor ?? "-",
                          ),
                          _buildDetailRow(
                            Icons.branding_watermark,
                            'Merk & Tipe',
                            '${widget.workOrder.merk ?? "-"} ${widget.workOrder.tipe ?? ""}',
                          ),
                          _buildDetailRow(
                            Icons.person,
                            'Customer',
                            widget.workOrder.namaCustomer ?? "-",
                          ),
                          _buildDetailRow(
                            Icons.engineering,
                            'Mekanik',
                            _getMechanicNames(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status: ${widget.workOrder.status.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(
                                    widget.workOrder.status,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Daftar Item
                  const Text(
                    'Daftar Item Part',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _woItems.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Text(
                                  'Belum ada item',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                ..._woItems.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            item.namaItem,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${item.qty}x',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            formatCurrency(item.harga),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            formatCurrency(item.subtotal),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'TOTAL :  ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      formatCurrencyWithSymbol(
                                        widget.workOrder.total,
                                      ),
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
                  ),

                  const SizedBox(height: 32),

                  // Tombol Selesai & Cetak (hanya jika belum completed)
                  if (widget.workOrder.status != 'completed')
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: widget.workOrder.status == 'on_progress'
                            ? _isLoading
                                  ? null
                                  : _completeAndPrint
                            : null,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isLoading ? 'Memproses...' : 'Cetak Nota Part',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMechanicNames() {
    // Jika sudah support multiple mechanics, ambil dari repository atau join
    // Untuk sekarang placeholder
    return widget.workOrder.namaMekanik ?? 'Belum ditugaskan';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'on_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'finished':
        return Colors.red.shade200;
      case 'paid':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
