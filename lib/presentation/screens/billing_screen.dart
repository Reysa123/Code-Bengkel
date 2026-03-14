import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/work_order.dart';
import '../../data/models/wo_item.dart';
import '../../data/repositories/work_order_repository.dart';
import '../../presentation/blocs/work_order_cubit.dart';
import '../../utils/number_format.dart'; // nf dan formatCurrencyWithSymbol
// printWorkOrderReceipt

class BillingScreen extends StatefulWidget {
  final WorkOrder workOrder;

  const BillingScreen({super.key, required this.workOrder});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<WoItem> _items = [];
  bool _isLoading = true;
  double _grandTotalBeforeDisc = 0.0;
  double _grandTotalAfterDisc = 0.0;

  final WorkOrderRepository _repo = WorkOrderRepository();

  @override
  void initState() {
    super.initState();
    _loadItems();
    // _items = List<WoItem>.from(widget.workOrder.items ?? []);
    _calculateTotals();
  }

  Future<void> _loadItems() async {
    try {
      final repo = WorkOrderRepository();

      final loadedItems = await repo.getWoItems(
        int.parse(widget.workOrder.noWo),
        'completed',
      );
      setState(() {
        _items = loadedItems;
        _isLoading = false;
        _calculateTotals();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _calculateTotals() {
    _grandTotalBeforeDisc = _items.fold(
      0.0,
      (sum, item) => sum + item.subtotal,
    );
    _grandTotalAfterDisc = _items.fold(0.0, (sum, item) {
      final disc = (item.harga * (item.discountPercent ?? 0) / 100) * item.qty;
      return sum + (item.subtotal - disc);
    });
    setState(() {});
  }

  Future<void> _updateItemDiscount(int index, double? percent) async {
    if (percent == null || percent < 0 || percent > 100) return;

    setState(() {
      _items[index] = _items[index].copyWith(discountPercent: percent);
    });
    _calculateTotals();
  }

  Future<void> _processPaymentAndPrint() async {
    if (_grandTotalAfterDisc <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total pembayaran tidak valid')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Update status ke 'finished' / 'paid'
      await _repo.finishWorkOrderAndPrint(
        int.parse(widget.workOrder.noWo),
        _grandTotalAfterDisc,
        _items,
        widget.workOrder.namaCustomer!,
      );

      // 2. Refresh WO di cubit (opsional)
      context.read<WorkOrderCubit>().loadAll();

      // 3. Cetak kwitansi
      final receiptData = await _repo.getWorkOrderForReceipt(
        widget.workOrder.noWo,
      );
     

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Billing Komplit! Kwitansi dicetak.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Billing WO ${widget.workOrder.noWo}'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Info WO
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.indigo.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pelanggan: ${widget.workOrder.namaCustomer ?? "-"}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Kendaraan: ${widget.workOrder.platNomor ?? "-"}'),
                      Text('Tanggal: ${widget.workOrder.tanggal}'),
                      const SizedBox(height: 8),
                      Text(
                        'Status: ${widget.workOrder.status.toUpperCase()}',
                        style: TextStyle(
                          color: _getStatusColor(widget.workOrder.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Daftar Item + Diskon
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final discPercent = item.discountPercent ?? 0.0;
                      final discAmount =
                          (item.harga * discPercent / 100) * item.qty;
                      final finalSubtotal = item.subtotal - discAmount;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaItem,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.qty} x ${formatCurrency(item.harga)}',
                                  ),
                                  Text(
                                    'Subtotal: ${formatCurrency(item.subtotal)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Input Diskon per item
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: discPercent > 0
                                          ? discPercent.toStringAsFixed(1)
                                          : '',
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,1}'),
                                        ),
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Diskon (%)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                        suffixText: '%',
                                      ),
                                      onChanged: (val) {
                                        final percent =
                                            double.tryParse(val) ?? 0.0;
                                        _updateItemDiscount(
                                          index,
                                          percent.clamp(0, 100),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    discAmount > 0
                                        ? '-${formatCurrency(discAmount)}'
                                        : '',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Total setelah diskon: ${formatCurrency(finalSubtotal)}',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Total Akhir + Tombol Bayar & Cetak
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Sebelum Diskon',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(formatCurrencyWithSymbol(_grandTotalBeforeDisc)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL YANG HARUS DIBAYAR',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatCurrencyWithSymbol(_grandTotalAfterDisc),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : widget.workOrder.status.toUpperCase() !=
                                    "COMPLETED"
                              ? null
                              : _processPaymentAndPrint,
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('BAYAR LUNAS & CETAK KWITANSI'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
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
