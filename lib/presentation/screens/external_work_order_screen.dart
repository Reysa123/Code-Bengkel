import 'package:bengkel/data/models/supplier.dart';
import 'package:bengkel/data/models/wo_item.dart';
import 'package:bengkel/data/repositories/work_order_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bengkel/data/models/external_order.dart';
import 'package:bengkel/presentation/blocs/external_order_cubit.dart'; // pastikan import yang benar (Bloc atau Cubit)
import 'package:bengkel/data/repositories/supplier_repository.dart';
import 'package:intl/intl.dart'; // tambahkan dependency intl jika belum ada

class ExternalOrderFormScreen extends StatefulWidget {
  final int? woId;
  const ExternalOrderFormScreen({super.key, this.woId});

  @override
  State<ExternalOrderFormScreen> createState() =>
      _ExternalOrderFormScreenState();
}

class _ExternalOrderFormScreenState extends State<ExternalOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tanggalController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _beliController = TextEditingController();
  final _jualController = TextEditingController();
  final _qtyController = TextEditingController();

  String? _selectedType;
  Supplier? _selectedVendor;
  List<Supplier> _vendors = [];
  final SupplierRepository _supplierRepo = SupplierRepository();

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tanggalController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(_selectedDate);
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    _vendors = await _supplierRepo.getAll();
    if (mounted) setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = DateFormat('yyyy-MM-dd HH:mm').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _deskripsiController.dispose();
    _beliController.dispose();
    _jualController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate() && _selectedVendor != null) {
      setState(() => _isSaving = true);

      final order = ExternalOrder(
        tanggal: _tanggalController.text,
        woId: widget.woId,
        type: _selectedType,
        deskripsi: _deskripsiController.text,
        beli: double.tryParse(_beliController.text),
        jual: double.tryParse(_jualController.text),
        qty: double.tryParse(_qtyController.text),
        vendor: _selectedVendor!.nama,
      );

      context.read<ExternalOrderBloc>().add(AddExternalOrder(order));

      final items = WoItem(
        woId: widget.woId,
        type: _selectedType?.toLowerCase() ?? '',
        itemId: 98000000,
        namaItem: _deskripsiController.text,
        qty: int.tryParse(_qtyController.text) ?? 0,
        harga: double.tryParse(_jualController.text) ?? 0,
        subtotal:
            (double.tryParse(_jualController.text) ?? 0) *
            (double.tryParse(_qtyController.text) ?? 0),
      );

      await WorkOrderRepository().insertItem([items]);

      if (!mounted) return;

      // Clear form
      _deskripsiController.clear();
      _beliController.clear();
      _jualController.clear();
      _qtyController.clear();
      setState(() {
        _selectedType = null;
        _selectedVendor = null;
        _selectedDate = DateTime.now();
        _tanggalController.text = DateFormat(
          'yyyy-MM-dd HH:mm',
        ).format(_selectedDate);
      });

      context.read<ExternalOrderBloc>().add(LoadExternalOrders());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('External Order berhasil disimpan'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('External Order'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // === FORM SECTION ===
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tambah External Order',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tanggal
                      TextFormField(
                        controller: _tanggalController,
                        //readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Tanggal',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),

                      // Type
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Tipe',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        items: ['Service', 'Part']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _selectedType = val),
                        validator: (v) => v == null ? 'Pilih tipe' : null,
                      ),
                      const SizedBox(height: 16),

                      // Deskripsi
                      TextFormField(
                        controller: _deskripsiController,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi / Nama Item',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // Harga Beli & Jual (Row)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _beliController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Harga Beli',
                                prefixIcon: const Icon(Icons.attach_money),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                              ),
                              validator: (v) => v!.isEmpty ? 'Wajib' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _jualController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Harga Jual',
                                prefixIcon: const Icon(Icons.sell),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                              ),
                              validator: (v) => v!.isEmpty ? 'Wajib' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Qty & Vendor
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Qty',
                                prefixIcon: const Icon(Icons.numbers),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                              ),
                              validator: (v) => v!.isEmpty ? 'Wajib' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<Supplier>(
                              initialValue: _selectedVendor,
                              decoration: InputDecoration(
                                labelText: 'Vendor',
                                prefixIcon: const Icon(Icons.business),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                              ),
                              items: _vendors
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v.nama),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedVendor = val),
                              validator: (v) =>
                                  v == null ? 'Pilih vendor' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Simpan External Order',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // === LIST SECTION ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar External Orders',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${context.watch<ExternalOrderBloc>().state.orders.where((o) => o.woId == widget.woId).length} items',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: BlocBuilder<ExternalOrderBloc, ExternalOrderState>(
                builder: (context, state) {
                  final filtered = state.orders
                      .where((o) => o.woId == widget.woId)
                      .toList();

                  if (state.status == ExternalOrderStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada external order',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              order.type?.substring(0, 1).toUpperCase() ?? '?',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            order.deskripsi ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${order.type} • ${order.vendor}'),
                              Text(
                                'Beli: Rp ${order.beli?.toStringAsFixed(0) ?? 0} | Jual: Rp ${order.jual?.toStringAsFixed(0) ?? 0}',
                              ),
                              Text(
                                'Qty: ${order.qty?.toStringAsFixed(0) ?? 0}',
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              context.read<ExternalOrderBloc>().add(
                                DeleteExternalOrder(order.id!),
                              );
                            },
                          ),
                        ),
                      );
                    },
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
