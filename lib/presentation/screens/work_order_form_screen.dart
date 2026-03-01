// lib/presentation/screens/work_order_form_screen.dart
// 🔥 WORK ORDER FORM SCREEN LENGKAP (428 baris)
// Sudah include: pilih kendaraan, mekanik, tambah multiple jasa + part,
// hitung total otomatis, dialog pencarian, simpan ke DB via Bloc,
// cetak billing langsung setelah simpan, validasi, dll.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/vehicle.dart';
import '../../data/models/mechanic.dart';
import '../../data/models/service.dart';
import '../../data/models/part.dart';
import '../../data/models/work_order.dart';
import '../../data/models/wo_item.dart';
import '../../presentation/blocs/vehicle_cubit.dart';
import '../../presentation/blocs/mechanic_cubit.dart';
import '../../presentation/blocs/service_cubit.dart';
import '../../presentation/blocs/part_cubit.dart';
import '../../presentation/blocs/work_order_cubit.dart';
import '../../utils/print_utils.dart';

class WorkOrderFormScreen extends StatefulWidget {
  const WorkOrderFormScreen({super.key});

  @override
  State<WorkOrderFormScreen> createState() => _WorkOrderFormScreenState();
}

class _WorkOrderFormScreenState extends State<WorkOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _noWoController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Data
  DateTime _selectedDate = DateTime.now();
  Vehicle? _selectedVehicle;
  Mechanic? _selectedMechanic;
  List<WoItem> selectedItems = [];
  double _grandTotal = 0.0;

  // Untuk dialog tambah item
  bool _isServiceTab = true;
  List<Service> _filteredServices = [];
  List<Part> _filteredParts = [];

  @override
  void initState() {
    super.initState();
    _generateNoWO();
    context.read<VehicleCubit>().loadAll();
    context.read<MechanicCubit>().loadAll();
    context.read<ServiceCubit>().loadAll();
    context.read<PartCubit>().loadAll();
  }

  void _generateNoWO() {
    _noWoController.text = DateFormat('yyMMddhhmmss').format(DateTime.now());
  }

  void _updateGrandTotal() {
    setState(() {
      _grandTotal = selectedItems.fold(0.0, (sum, item) => sum + item.subtotal);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // ================================== DIALOG TAMBAH ITEM ==================================
  void _showAddItemDialog() {
    _searchController.clear();
    _isServiceTab = true;
    _loadFilteredItems();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Jasa / Part'),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: Column(
              children: [
                // Tab Jasa / Part
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Jasa')),
                    ButtonSegment(value: false, label: Text('Part')),
                  ],
                  selected: {_isServiceTab},
                  onSelectionChanged: (set) {
                    setDialogState(() {
                      _isServiceTab = set.first;
                      _searchController.clear();
                      _loadFilteredItems();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Search
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Cari...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _loadFilteredItems(setDialogState),
                ),
                const SizedBox(height: 12),
                // List items
                Expanded(
                  child: _isServiceTab
                      ? _buildServiceList(setDialogState)
                      : _buildPartList(setDialogState),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  void _loadFilteredItems([StateSetter? setDialogState]) {
    final query = _searchController.text.toLowerCase();

    if (_isServiceTab) {
      final services = context.read<ServiceCubit>().state is ServiceLoaded
          ? (context.read<ServiceCubit>().state as ServiceLoaded).services
          : <Service>[];
      _filteredServices = services
          .where((s) => s.nama.toLowerCase().contains(query))
          .toList();
    } else {
      final parts = context.read<PartCubit>().state is PartLoaded
          ? (context.read<PartCubit>().state as PartLoaded).parts
          : <Part>[];
      _filteredParts = parts
          .where(
            (p) =>
                p.nama.toLowerCase().contains(query) ||
                p.kode.toLowerCase().contains(query),
          )
          .toList();
    }

    if (setDialogState != null) setDialogState(() {});
  }

  Widget _buildServiceList(StateSetter setDialogState) {
    return ListView.builder(
      itemCount: _filteredServices.length,
      itemBuilder: (context, index) {
        final service = _filteredServices[index];
        return ListTile(
          title: Text(service.nama),
          subtitle: Text('Rp ${service.harga.toStringAsFixed(0)}'),
          trailing: const Icon(Icons.add_circle, color: Colors.green),
          onTap: () {
            final newItem = WoItem(
              type: 'service',
              itemId: service.id!,
              namaItem: service.nama,
              qty: 1,
              harga: service.harga,
              subtotal: service.harga,
            );
            setState(() {
              selectedItems.add(newItem);
              _updateGrandTotal();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildPartList(StateSetter setDialogState) {
    return ListView.builder(
      itemCount: _filteredParts.length,
      itemBuilder: (context, index) {
        final part = _filteredParts[index];
        return ListTile(
          title: Text('${part.kode} - ${part.nama}'),
          subtitle: Text(
            'Stok: ${part.stok} | Rp ${part.hargaJual.toStringAsFixed(0)}',
          ),
          trailing: const Icon(Icons.add_circle, color: Colors.blue),
          onTap: () {
            if (part.stok <= 0) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Stok part habis!')));
              return;
            }
            final newItem = WoItem(
              type: 'part',
              itemId: part.id!,
              namaItem: part.nama,
              qty: 1,
              harga: part.hargaJual,
              subtotal: part.hargaJual,
            );
            setState(() {
              selectedItems.add(newItem);
              _updateGrandTotal();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // ================================== SAVE WORK ORDER ==================================
  void _saveWorkOrder() async {
    if (_formKey.currentState!.validate() &&
        _selectedVehicle != null &&
        _selectedMechanic != null &&
        selectedItems.isNotEmpty) {
      final wo = WorkOrder(
        noWo: _noWoController.text,
        tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
        vehicleId: _selectedVehicle!.id!,
        mechanicId: _selectedMechanic!.id!,
        total: _grandTotal,
        status: 'pending',
      );

      context.read<WorkOrderCubit>().createWorkOrder(wo, selectedItems);

      // Tunggu success dari Bloc
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Menyimpan Work Order...')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua data & tambahkan minimal 1 item'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Work Order Baru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _grandTotal > 0
                ? () => printBilling(
                    WorkOrder(
                      noWo: _noWoController.text,
                      tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
                      vehicleId: _selectedVehicle?.id ?? 0,
                      mechanicId: _selectedMechanic?.id ?? 0,
                      total: _grandTotal,
                    ),
                    selectedItems,
                  )
                : null,
            tooltip: 'Cetak Preview',
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<WorkOrderCubit, WorkOrderState>(
            listener: (context, state) {
              if (state is WorkOrderSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Work Order berhasil disimpan!'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Cetak otomatis setelah simpan
                Future.delayed(const Duration(milliseconds: 800), () {
                  printBilling(
                    WorkOrder(
                      noWo: _noWoController.text,
                      tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
                      vehicleId: _selectedVehicle?.id ?? 0,
                      mechanicId: _selectedMechanic?.id ?? 0,
                      total: _grandTotal,
                    ),
                    selectedItems,
                  );
                });
                Navigator.pop(context); // kembali ke list
              } else if (state is WorkOrderError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${state.message}')),
                );
              }
            },
          ),
        ],
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // No WO & Tanggal
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _noWoController,
                        decoration: const InputDecoration(
                          labelText: 'No. Work Order',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pilih Kendaraan
                BlocBuilder<VehicleCubit, VehicleState>(
                  builder: (context, state) {
                    if (state is VehicleLoaded) {
                      return DropdownButtonFormField<Vehicle>(
                        value: _selectedVehicle,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Kendaraan',
                          border: OutlineInputBorder(),
                        ),
                        items: state.vehicles.map((v) {
                          return DropdownMenuItem(
                            value: v,
                            child: Text('${v.platNomor} - ${v.merk} ${v.tipe}'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedVehicle = val),
                        validator: (val) =>
                            val == null ? 'Pilih kendaraan' : null,
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 16),

                // Pilih Mekanik
                BlocBuilder<MechanicCubit, MechanicState>(
                  builder: (context, state) {
                    if (state is MechanicLoaded) {
                      return DropdownButtonFormField<Mechanic>(
                        value: _selectedMechanic,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Mekanik',
                          border: OutlineInputBorder(),
                        ),
                        items: state.mechanics.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(m.nama),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedMechanic = val),
                        validator: (val) =>
                            val == null ? 'Pilih mekanik' : null,
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 24),

                // Tombol Tambah Item
                ElevatedButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Jasa / Part'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 16),

                // List Item yang sudah ditambahkan
                const Text(
                  'Item Pekerjaan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  height: 300,
                  child: selectedItems.isEmpty
                      ? const Center(child: Text('Belum ada item'))
                      : ListView.builder(
                          itemCount: selectedItems.length,
                          itemBuilder: (context, index) {
                            final item = selectedItems[index];
                            return ListTile(
                              title: Text(item.namaItem),
                              subtitle: Text(
                                '${item.qty} x Rp ${item.harga.toStringAsFixed(0)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Rp ${item.subtotal.toStringAsFixed(0)}',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        selectedItems.removeAt(index);
                                        _updateGrandTotal();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),

                // Grand Total
                Card(
                  color: Colors.indigo.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp ${_grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Catatan
                TextFormField(
                  controller: _catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveWorkOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'SIMPAN & CETAK WORK ORDER',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noWoController.dispose();
    _catatanController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
