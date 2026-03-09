// lib/presentation/screens/work_order_form_screen.dart

import 'package:bengkel/data/repositories/work_order_repository.dart';
import 'package:bengkel/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/vehicle.dart';
import '../../data/models/mechanic.dart';
import '../../data/models/service.dart';
import '../../data/models/part.dart';
import '../../data/models/work_order.dart';
import '../../data/models/wo_item.dart';
import '../../presentation/blocs/mechanic_cubit.dart';
import '../../presentation/blocs/service_cubit.dart';
import '../../presentation/blocs/part_cubit.dart';
import '../../presentation/blocs/work_order_cubit.dart';

class EditWorkOrderScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialVehicle;

  const EditWorkOrderScreen({super.key, this.initialVehicle});

  @override
  State<EditWorkOrderScreen> createState() => _EditWorkOrderScreenState();
}

class _EditWorkOrderScreenState extends State<EditWorkOrderScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  List<Service> _filteredServices = [];
  List<Part> _filteredParts = [];
  int _kmTerakhir = 0;
  // Controllers
  final TextEditingController _noWoController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode kmFocusNode = FocusNode();
  // Data
  Mechanic? _selectedMechanic;
  final List<WoItem> _selectedItems = [];
  double _grandTotal = 0.0;
  List<Map<String, dynamic>>? get _selectedVehicle => widget.initialVehicle;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateNoWO();

    context.read<MechanicCubit>().loadAll();
    context.read<ServiceCubit>().loadAll();
    context.read<PartCubit>().loadAll();
  }

  void _generateNoWO() {
    _noWoController.text = _selectedVehicle != null
        ? '${_selectedVehicle!.first['no_wo']}'
        : DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    _kmTerakhir = widget.initialVehicle != null
        ? widget.initialVehicle!.first['kmTerakhir'] ?? 0
        : 0;
    _kmController.text = _kmTerakhir > 0 ? _kmTerakhir.toString() : '0';
    _catatanController.text = widget.initialVehicle != null
        ? widget.initialVehicle!.first['catatan'] ?? ''
        : '';
    _selectedMechanic = widget.initialVehicle != null
        ? Mechanic(
            id: widget.initialVehicle!.first['mechanic_id'],
            nama: widget.initialVehicle!.first['nama_mekanik'] ?? '',
          )
        : null;
    for (var item in widget.initialVehicle ?? []) {
      _selectedItems.add(
        WoItem(
          woId: int.parse(_noWoController.text),
          type: item['type_item'],
          itemId: item['item_id'],
          namaItem: item['nama_item'],
          qty: item['qty_item'],
          harga: item['harga_item'],
          subtotal: item['subtotal_item'],
          status: item['status_item'],
        ),
      );
    }
  }

  void _updateGrandTotal() {
    setState(() {
      _grandTotal = _selectedItems.fold(
        0.0,
        (sum, item) => sum + item.subtotal,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.initialVehicle!.first;
    var widthLabel = 130.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buat PKB / Work Order'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                _noWoController.text,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade900,
              foregroundColor: Colors.white,
            ),
            onPressed:
                _selectedVehicle!.first['status'] == 'pending' ||
                    _selectedVehicle!.first['status'] == 'on_progress'
                ? _saveWorkOrder
                : _selectedVehicle!.first['status'] == 'completed'
                ? _batalCompleted
                : null,
            icon: const Icon(Icons.save, color: Colors.green),
            label:
                _selectedVehicle!.first['status'] == 'pending' ||
                    _selectedVehicle!.first['status'] == 'on_progress'
                ? const Text(
                    'Simpan & Update',
                    style: TextStyle(color: Colors.white),
                  )
                : const Text(
                    'Batal Komplit',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Section 1: Detail Kendaraan (Mirip createpkb.dart)
              ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        'No. Polisi',
                        vehicle['plat_nomor'] ?? '-',
                        widthLabel,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        'Merk/Tipe',
                        '${vehicle['merk'] ?? '-'} ${vehicle['tipe'] ?? '-'}',
                        widthLabel,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        'Warna',
                        vehicle['warna'] ?? '-',
                        widthLabel,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        'Tahun',
                        vehicle['tahun'] ?? '-',
                        widthLabel,
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 30),

              // Section 2: Tab System
              TabBar(
                controller: _tabController,
                labelColor: Colors.redAccent.shade700,
                indicatorColor: Colors.redAccent.shade700,
                tabs: const [
                  Tab(text: 'Header'),
                  Tab(text: 'Pekerjaan (Jasa)'),
                  Tab(text: 'Suku Cadang (Part)'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabHeader(),
                    _buildTabItems('service'),
                    _buildTabItems('part'),
                  ],
                ),
              ),

              // Bottom Total
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'GRAND TOTAL: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Rp ${nf.format(_grandTotal)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _batalCompleted() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batal Status Completed'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan status completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Update status item menjadi pending
              await WorkOrderRepository().updateStatus(
                int.parse(_noWoController.text),
                'on_progress',
                0,
              );
              // Simpan perubahan
              Navigator.pop(context); // Tutup dialog
            },
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _saveWorkOrder() {
    if (_formKey.currentState!.validate() &&
        _selectedVehicle != null &&
        _selectedItems.isNotEmpty) {
      if (_kmController.text.isNotEmpty &&
          (int.tryParse(_kmController.text) ?? 0) >= _kmTerakhir) {
        // print(_catatanController.text);
        final wo = WorkOrder(
          noWo: _selectedVehicle!.first['no_wo'],
          tanggal:
              _selectedVehicle!.first['tanggal'] ??
              DateTime.now().toIso8601String(),
          vehicleId: _selectedVehicle!.first['vehicle_id'],
          mechanicId: _selectedMechanic?.id ?? 0,
          total: _grandTotal,
          status: _selectedVehicle!.first['status'] ?? 'pending',
          catatan: _catatanController.text,
          kmTerakhir: int.tryParse(_kmController.text) ?? 0,
        );
        context.read<WorkOrderCubit>().updateWorkOrder(wo, _selectedItems);

        Navigator.pop(
          context,
          true,
        ); // Kembali ke halaman sebelumnya dengan hasil "true" untuk refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'KM terakhir harus diisi & valid, KM terakhir ( $_kmTerakhir )',
            ),
          ),
        );
        _tabController.animateTo(0); // Pindah ke tab pertama
        kmFocusNode.requestFocus();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi data & minimal 1 item pekerjaan'),
        ),
      );
    }
  }

  void _loadFilteredItems() {
    final query = _searchController.text.toLowerCase();

    // Ambil state terbaru dari Cubit
    final serviceState = context.read<ServiceCubit>().state;
    final partState = context.read<PartCubit>().state;

    setState(() {
      // 1. Filter Jasa
      if (serviceState is ServiceLoaded) {
        _filteredServices = serviceState.services.where((s) {
          return s.nama.toLowerCase().contains(query);
        }).toList();
      }

      // 2. Filter Part
      if (partState is PartLoaded) {
        _filteredParts = partState.parts.where((p) {
          return p.nama.toLowerCase().contains(query) ||
              p.kode.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _showAddItemDialog(bool isService) {
    _searchController.clear();
    _loadFilteredItems(); // Inisialisasi data awal

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isService ? 'Pilih Jasa / Pekerjaan' : 'Pilih Suku Cadang',
          ),
          content: SizedBox(
            width:
                800, // Lebar fixed agar terlihat seperti desktop/web style di file contoh
            height: 500,
            child: Column(
              children: [
                // Search Field bergaya Textfields.dart
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari ${isService ? "Jasa" : "Part"}...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    // Trigger filter saat mengetik
                    _loadFilteredItems();
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 15),

                // Header Tabel di dalam Dialog
                Container(
                  color: Colors.blue.shade900,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 40,
                        child: Text(
                          'No',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          isService ? 'Nama Jasa' : 'Nama Part',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          'Harga',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 50),
                    ],
                  ),
                ),

                // List Data
                Expanded(
                  child: ListView.separated(
                    itemCount: isService
                        ? _filteredServices.length
                        : _filteredParts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (isService) {
                        final s = _filteredServices[index];
                        return ListTile(
                          leading: Text('${index + 1}'),
                          title: Text(s.nama),
                          trailing: Text('Rp ${nf.format(s.harga)}'),
                          onTap: () {
                            _addItemToWO('service', s.id!, s.nama, s.harga);
                            Navigator.pop(context);
                          },
                        );
                      } else {
                        final p = _filteredParts[index];
                        return ListTile(
                          leading: Text('${index + 1}'),
                          title: Text(p.nama),
                          subtitle: Text('Kode: ${p.kode} | Stok: ${p.stok}'),
                          trailing: Text(
                            'Rp ${nf.format(p.hargaJual)}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          enabled: p.stok > 0,
                          onTap: () {
                            _addItemToWO('part', p.id!, p.nama, p.hargaJual);
                            Navigator.pop(context);
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi helper untuk menambah ke list utama
  void _addItemToWO(String type, int id, String nama, double harga) {
    // print('Adding item to WO: type=$type, id=$id, nama=$nama, harga=$harga');
    setState(() {
      // Cek duplikasi seperti di createpkb.dart (opsional)
      bool exists = _selectedItems.any(
        (item) => item.itemId == id && item.type == type,
      );
      // print('exists: $exists');
      if (exists) {
        // Jika sudah ada, tambahkan Qty (khusus Part)
        int idx = _selectedItems.indexWhere(
          (item) => item.itemId == id && item.type == type,
        );
        _selectedItems[idx] = WoItem(
          woId: int.parse(_noWoController.text),
          type: type,
          itemId: id,
          namaItem: nama,
          qty: _selectedItems[idx].qty + 1,
          harga: harga,
          subtotal: (_selectedItems[idx].qty + 1) * harga,
        );
      } else {
        _selectedItems.add(
          WoItem(
            woId: int.parse(_noWoController.text),
            type: type,
            itemId: id,
            namaItem: nama,
            qty: 1,
            harga: harga,
            subtotal: harga,
          ),
        );
      }
      _updateGrandTotal();
    });
  }

  // Widget bantuan untuk baris informasi
  Widget _buildInfoRow(String title, String content, double labelWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(title, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 10, child: Text(':')),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kilometer Terakhir:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            child: TextFormField(
              enabled:
                  _selectedVehicle!.first['status'] == 'pending' ||
                  _selectedVehicle!.first['status'] == 'on_progress',
              controller: _kmController,
              focusNode: kmFocusNode,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '0',
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pilih Mekanik:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          BlocBuilder<MechanicCubit, MechanicState>(
            builder: (context, state) {
              if (state is MechanicLoaded) {
                return DropdownButtonFormField<Mechanic>(
                  enableFeedback:
                      _selectedVehicle!.first['status'] == 'pending' ||
                      _selectedVehicle!.first['status'] == 'on_progress',
                  initialValue: _selectedMechanic,
                  decoration: InputDecoration(border: OutlineInputBorder()),
                  items: state.mechanics
                      .map(
                        (m) => DropdownMenuItem(value: m, child: Text(m.nama)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedMechanic = val),
                );
              }
              return const CircularProgressIndicator();
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Keluhan / Catatan:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            enabled:
                _selectedVehicle!.first['status'] == 'pending' ||
                _selectedVehicle!.first['status'] == 'on_progress',
            controller: _catatanController,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Masukkan keluhan pelanggan...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItems(String type) {
    final filteredItems = _selectedItems
        .where((item) => item.type == type)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed:
                _selectedVehicle!.first['status'] == 'finished' ||
                    _selectedVehicle!.first['status'] == 'paid' ||
                    _selectedVehicle!.first['status'] == 'completed'
                ? null
                : () => _showAddItemDialog(type == 'service'),
            icon: const Icon(Icons.add),
            label: Text(type == 'service' ? 'Tambah Jasa' : 'Tambah Part'),
          ),
        ),
        // Header Tabel
        Card(
          color: Colors.cyanAccent.shade700,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 40,
                  child: Text('No', style: TextStyle(color: Colors.white)),
                ),
                const Expanded(
                  child: Text(
                    'Deskripsi',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(
                  width: 100,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(
                  width: 120,
                  child: Text(
                    'Subtotal',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return Card(
                child: ListTile(
                  leading: Text('${index + 1}'),
                  title: Text(item.namaItem),
                  subtitle: type == 'part'
                      ? Text('Harga: @${nf.format(item.harga)}')
                      : null,
                  trailing: SizedBox(
                    width: 250,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'x ${item.qty}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          'Rp ${nf.format(item.subtotal)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: item.status == 'completed'
                                ? Colors.grey
                                : Colors.red,
                          ),
                          onPressed: item.status == 'completed'
                              ? null
                              : () => setState(() {
                                  _selectedItems.remove(item);
                                  _updateGrandTotal();
                                }),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
