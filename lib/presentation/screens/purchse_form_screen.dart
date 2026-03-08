import 'package:bengkel/presentation/blocs/suppliers_cubit.dart';
import 'package:bengkel/utils/print_purchase.dart';
import 'package:bengkel/utils/ribuan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/supplier.dart';
import '../../data/models/part.dart';
import '../../data/models/purchase.dart';
import '../../data/models/purchase_item.dart';
import '../../presentation/blocs/part_cubit.dart';
import '../../presentation/blocs/purchase_cubit.dart';

class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  Supplier? _selectedSupplier;
  final List<PurchaseItem> _items = [];
  double _grandTotal = 0.0;
  NumberFormat nf = NumberFormat('#,###');
  late String _noPurchase;
  DateTime _tanggal = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<SupplierCubit>().loadAll();
    context.read<PartCubit>().loadAll();

    _noPurchase =
        'PB-${DateFormat('yyyyMMdd').format(DateTime.now())}-${const Uuid().v4().substring(0, 6).toUpperCase()}';
  }

  void _updateGrandTotal() {
    setState(() {
      _grandTotal = _items.fold(0.0, (sum, item) => sum + item.subtotal);
    });
  }

  Future<void> _showAddItemDialog() async {
    Part? selectedPart;
    final qtyController = TextEditingController(text: '1');
    final hargaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: Colors.blue.shade800,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Tambah Part ke Pembelian',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade900,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pilih Part
                BlocBuilder<PartCubit, PartState>(
                  builder: (context, state) {
                    if (state is PartLoaded) {
                      return DropdownButtonFormField<Part>(
                        initialValue: selectedPart,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Pilih Part',
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          prefixIcon: Icon(
                            Icons.build_circle_rounded,
                            color: Colors.blue.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue.shade700,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: state.parts.map((p) {
                          return DropdownMenuItem<Part>(
                            value: p,
                            child: Text(
                              '${p.kode} - ${p.nama} (Stok: ${p.stok})',
                              style: const TextStyle(fontSize: 15),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPart = value;
                            if (value != null) {
                              hargaController.text = nf.format(value.hargaBeli);
                            }
                          });
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),

                const SizedBox(height: 20),

                // Jumlah (Qty)
                TextFormField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah (Qty)',
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                    prefixIcon: Icon(
                      Icons.format_list_numbered_rounded,
                      color: Colors.blue.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade700,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),

                const SizedBox(height: 20),

                // Harga Beli
                TextFormField(
                  readOnly: true,
                  controller: hargaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                    ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Harga Beli per Unit',
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        'Rp. ',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade700,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(color: Colors.grey, height: 1),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'BATAL',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text(
              'TAMBAH PART',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              if (selectedPart == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pilih part terlebih dahulu'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final qty =
                  int.tryParse(qtyController.text.replaceAll(',', '')) ?? 1;
              final harga =
                  double.tryParse(hargaController.text.replaceAll(',', '')) ??
                  0.0;
              final subtotal = qty * harga;

              setState(() {
                _items.add(
                  PurchaseItem(
                    purchaseId: 0,
                    partId: selectedPart!.id!,
                    partName: selectedPart!.nama,
                    qty: qty,
                    hargaBeli: harga,
                    subtotal: subtotal,
                  ),
                );
                _updateGrandTotal();
              });

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _savePurchase() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih supplier terlebih dahulu')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tambahkan minimal 1 part')));
      return;
    }

    final purchase = Purchase(
      noPurchase: _noPurchase,
      tanggal: DateFormat('yyyy-MM-dd').format(_tanggal),
      supplierId: _selectedSupplier!.id!,
      total: _grandTotal,
    );

    context.read<PurchaseCubit>().createPurchase(purchase, _items);

    // Listener di BlocBuilder bisa menangani navigasi setelah success
  }

  printNota(
    Purchase purchase,
    List<PurchaseItem> items,
    List<Part> allParts,
    String supplierName,
  ) async {
    await printPurchaseNota(purchase, items, allParts, supplierName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembelian Part dari Supplier')),
      body: BlocListener<PurchaseCubit, PurchaseState>(
        listener: (context, state) {
          if (state is PurchaseSuccess) {
            printNota(
              Purchase(
                id: state.purchaseId,
                noPurchase: _noPurchase,
                tanggal: DateFormat('yyyy-MM-dd').format(_tanggal),
                supplierId: _selectedSupplier!.id!,
                total: _grandTotal,
              ),
              _items,
              context.read<PartCubit>().state is PartLoaded
                  ? (context.read<PartCubit>().state as PartLoaded).parts
                  : [],
              _selectedSupplier!.nama,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pembelian berhasil disimpan & stok diupdate'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is PurchaseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // No & Tanggal
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'No: $_noPurchase',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _tanggal,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) setState(() => _tanggal = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tanggal'),
                        child: Text(DateFormat('dd MMM yyyy').format(_tanggal)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Supplier
              BlocBuilder<SupplierCubit, SupplierState>(
                builder: (context, state) {
                  if (state is SupplierLoaded) {
                    return DropdownButtonFormField<Supplier>(
                      initialValue: _selectedSupplier,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Supplier',
                      ),
                      items: state.suppliers
                          .map(
                            (s) =>
                                DropdownMenuItem(value: s, child: Text(s.nama)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSupplier = val),
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Part'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),

              if (_items.isNotEmpty) ...[
                const Text(
                  'Daftar Part Dibeli',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ..._items.asMap().entries.map((e) {
                  final index = e.key;
                  final item = e.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        'Part Id : ${item.partId}, Part Name : ${item.partName} × ${item.qty}',
                      ),
                      subtitle: Text(
                        'Rp ${nf.format(item.hargaBeli)} → Subtotal Rp ${nf.format(item.subtotal)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _items.removeAt(index);
                            _updateGrandTotal();
                          });
                        },
                      ),
                    ),
                  );
                }),
              ],

              const Divider(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp ${nf.format(_grandTotal)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _savePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                  child: const Text(
                    'SIMPAN PEMBELIAN & TAMBAH STOK',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
