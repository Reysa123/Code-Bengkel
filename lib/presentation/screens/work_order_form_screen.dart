// lib/presentation/screens/work_order_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
  // Menerima parameter opsional kendaraan dari pencarian plat nomor
  final Vehicle? initialVehicle;

  const WorkOrderFormScreen({super.key, this.initialVehicle});

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
  List<WoItem> _selectedItems = [];
  double _grandTotal = 0.0;

  // Untuk dialog tambah item
  bool _isServiceTab = true;
  List<Service> _filteredServices = [];
  List<Part> _filteredParts = [];

  @override
  void initState() {
    super.initState();
    _generateNoWO();

    // LOGIKA PENTING: Jika ada data kendaraan dari parameter, set ke state
    if (widget.initialVehicle != null) {
      _selectedVehicle = widget.initialVehicle;
    }

    context.read<VehicleCubit>().loadAll();
    context.read<MechanicCubit>().loadAll();
    context.read<ServiceCubit>().loadAll();
    context.read<PartCubit>().loadAll();
  }

  void _generateNoWO() {
    final uuid = const Uuid().v4().substring(0, 8).toUpperCase();
    _noWoController.text =
        "${DateFormat('yyMMddhhmmss').format(DateTime.now())}";
  }

  void _updateGrandTotal() {
    setState(() {
      _grandTotal = _selectedItems.fold(
        0.0,
        (sum, item) => sum + item.subtotal,
      );
    });
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
            setState(() {
              _selectedItems.add(
                WoItem(
                  type: 'service',
                  itemId: service.id!,
                  namaItem: service.nama,
                  qty: 1,
                  harga: service.harga,
                  subtotal: service.harga,
                ),
              );
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
              ).showSnackBar(const SnackBar(content: Text('Stok habis!')));
              return;
            }
            setState(() {
              _selectedItems.add(
                WoItem(
                  type: 'part',
                  itemId: part.id!,
                  namaItem: part.nama,
                  qty: 1,
                  harga: part.hargaJual,
                  subtotal: part.hargaJual,
                ),
              );
              _updateGrandTotal();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _saveWorkOrder() {
    if (_formKey.currentState!.validate() &&
        _selectedVehicle != null &&
        _selectedMechanic != null &&
        _selectedItems.isNotEmpty) {
      final wo = WorkOrder(
        noWo: _noWoController.text,
        tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
        vehicleId: _selectedVehicle!.id!,
        mechanicId: _selectedMechanic!.id!,
        total: _grandTotal,
        status: 'pending',
      );
      context.read<WorkOrderCubit>().createWorkOrder(wo, _selectedItems);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data & minimal 1 item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Work Order Baru')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<WorkOrderCubit, WorkOrderState>(
            listener: (context, state) {
              if (state is WorkOrderSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tersimpan!'),
                    backgroundColor: Colors.green,
                  ),
                );
                printBilling(
                  WorkOrder(
                    noWo: _noWoController.text,
                    tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
                    vehicleId: _selectedVehicle?.id ?? 0,
                    mechanicId: _selectedMechanic?.id ?? 0,
                    total: _grandTotal,
                  ),
                  _selectedItems,
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Field Plat Nomor (Read Only jika dari search)
                TextFormField(
                  controller: _noWoController,
                  decoration: const InputDecoration(
                    labelText: 'No. Work Order',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 16),

                // Dropdown Kendaraan
                BlocBuilder<VehicleCubit, VehicleState>(
                  builder: (context, state) {
                    if (state is VehicleLoaded) {
                      final v = state.vehicles.firstWhere(
                        (v) => v.id == _selectedVehicle?.id,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Baris 1: Plat Nomor & Merk (Bold)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                v.platNomor,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                v.merk,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Baris 2: Model, Warna, Tahun (Informasi Lengkap)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${v.tipe} (${v.tahun})",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  v.warna,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 1), // Garis pemisah antar item
                        ],
                      );
                    }
                    return const LinearProgressIndicator();
                  },
                ),
                const SizedBox(height: 16),

                // Mekanik
                BlocBuilder<MechanicCubit, MechanicState>(
                  builder: (context, state) {
                    if (state is MechanicLoaded) {
                      return DropdownButtonFormField<Mechanic>(
                        value: _selectedMechanic,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Mekanik',
                          border: OutlineInputBorder(),
                        ),
                        items: state.mechanics
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.nama),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedMechanic = val),
                        validator: (val) =>
                            val == null ? 'Pilih mekanik' : null,
                      );
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Jasa / Part'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 16),

                // Daftar Item
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _selectedItems.length,
                    itemBuilder: (context, index) {
                      final item = _selectedItems[index];
                      return ListTile(
                        title: Text(item.namaItem),
                        trailing: Text(
                          'Rp ${item.subtotal.toStringAsFixed(0)}',
                        ),
                        onLongPress: () => setState(() {
                          _selectedItems.removeAt(index);
                          _updateGrandTotal();
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Total
                Text(
                  'TOTAL: Rp ${_grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveWorkOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('SIMPAN & CETAK'),
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
