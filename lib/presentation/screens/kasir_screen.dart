// lib/presentation/screens/kasir_screen.dart

import 'package:bengkel/utils/printkasir.dart';
import 'package:bengkel/utils/ribuan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../data/models/work_order.dart';
import '../../data/models/wo_item.dart';
import '../../data/repositories/work_order_repository.dart';
import '../../presentation/blocs/work_order_cubit.dart';
import '../../utils/number_format.dart'; // nf dan formatCurrencyWithSymbol
// printWorkOrderReceipt

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  WorkOrder? _selectedWO;
  List<WoItem> items = [];
  double total = 0.0;
  double _totalDue = 0.0;
  double _paidAmount = 0.0;
  double _change = 0.0;
  bool _isLoading = false;
  final TextEditingController _paidController = TextEditingController();
  final WorkOrderRepository _repo = WorkOrderRepository();

  @override
  void initState() {
    super.initState();
    context.read<WorkOrderCubit>().loadAll(); // refresh list WO
  }

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  Future<void> _loadWOItems(WorkOrder wo) async {
    setState(() {
      _isLoading = true;

      _paidAmount = 0.0;
      _change = 0.0;
      _paidController.clear();
    });

    try {
      final itemss = await _repo.getWoItems(int.parse(wo.noWo), 'completed');
      setState(() {
        items = itemss;
        _totalDue = items.fold(0.0, (sum, item) {
          final disc =
              (item.harga * ((item.discountPercent ?? 0) / 100)) * item.qty;

          return sum + (item.subtotal - disc);
        });
        total = items.fold(0.0, (sum, item) {
          return sum + item.subtotal;
        });
        _isLoading = false;
        _selectedWO = wo;
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

  void _updatePaidAmount(String value) {
    final cleaned = value.replaceAll('.', '');
    final amount = double.tryParse(cleaned) ?? 0.0;
    setState(() {
      _paidAmount = amount;
      _change = amount - _totalDue;
    });
  }

  Future<void> _processPaymentAndPrint(String nacus, String tglWo) async {
    if (_selectedWO == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih Work Order terlebih dahulu')),
      );
      return;
    }

    if (_paidAmount < _totalDue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah pembayaran kurang dari total tagihan'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Update status ke 'paid' / 'finished'
      await _repo.kasirFinishWorkOrder(
        _selectedWO!.noWo,
        _paidAmount,
        nacus,
        tglWo,
      );
      if (!mounted) return;
      // 2. Refresh list WO
      context.read<WorkOrderCubit>().loadAll();

      // 3. Cetak kwitansi
      final pdfBytes = await generateReceiptPdf(
        workOrder: _selectedWO!,
        items: items,
        grandTotalBeforeDisc: total,
        grandTotalAfterDisc: _paidAmount,
        cashierName: "Kasir", // ambil dari auth atau input jika ada
      );
      // await printWorkOrderReceipt(wo, items);

      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'Kwitansi_WO_${_selectedWO!.noWo}.pdf',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran lunas! Kwitansi dicetak.'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        _selectedWO = null;
        items = [];
        _totalDue = 0.0;
        _paidAmount = 0.0;
        _change = 0.0;
        _paidController.clear();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pembayaran: $e'),
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
        title: const Text('Kasir Pembayaran'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<WorkOrderCubit, WorkOrderState>(
        builder: (context, state) {
          if (state is WorkOrderLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WorkOrderError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is WorkOrderLoaded) {
            final pendingWOs = state.workOrders
                .where((wo) => wo.status == 'finished')
                .toList();

            return Column(
              children: [
                // Daftar WO yang belum lunas
                Expanded(
                  child: pendingWOs.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada Work Order yang menunggu pembayaran',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: pendingWOs.length,
                          itemBuilder: (context, index) {
                            final wo = pendingWOs[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.orange,
                                  child: Icon(
                                    Icons.receipt_long,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  wo.noWo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Customer: ${wo.namaCustomer ?? "-"}'),
                                    Text('Kendaraan: ${wo.platNomor ?? "-"}'),
                                    Text(
                                      'Tagihan: ${formatCurrencyWithSymbol(_totalDue)}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => _loadWOItems(wo),
                              ),
                            );
                          },
                        ),
                ),

                // Form Pembayaran (jika WO sudah dipilih)
                if (_selectedWO != null)
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Tagihan: ${formatCurrencyWithSymbol(_totalDue)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _paidController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,]'),
                            ),
                            ThousandsSeparatorInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Jumlah Pembayaran (Rp)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.attach_money),
                          ),
                          onChanged: _updatePaidAmount,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kembalian:'),
                            Text(
                              _change >= 0
                                  ? formatCurrencyWithSymbol(_change)
                                  : 'Kurang ${formatCurrencyWithSymbol(_change.abs())}',
                              style: TextStyle(
                                color: _change >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _processPaymentAndPrint(
                                    '${_selectedWO!.namaCustomer}-${_selectedWO!.platNomor}',
                                    _selectedWO!.tanggal,
                                  ),
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
                                : const Icon(Icons.print),
                            label: Text(
                              _isLoading
                                  ? 'Memproses...'
                                  : 'BAYAR LUNAS & CETAK KWITANSI',
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }

          return const Center(child: Text('Tidak ada data'));
        },
      ),
    );
  }
}
