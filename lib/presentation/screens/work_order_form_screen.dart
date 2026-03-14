// lib/presentation/screens/work_order_form_screen.dart

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

class WorkOrderFormScreen extends StatefulWidget {
  final Vehicle? initialVehicle;

  const WorkOrderFormScreen({super.key, this.initialVehicle});

  @override
  State<WorkOrderFormScreen> createState() => _WorkOrderFormScreenState();
}

class _WorkOrderFormScreenState extends State<WorkOrderFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final NumberFormat nf = NumberFormat('#,###');
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
  final DateTime _selectedDate = DateTime.now();
  Mechanic? _selectedMechanic;
  final List<WoItem> _selectedItems = [];
  double _grandTotal = 0.0;
  Vehicle? get _selectedVehicle => widget.initialVehicle;
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
    _noWoController.text = DateFormat('yyMMddHHmmss').format(DateTime.now());
    _kmTerakhir = widget.initialVehicle != null
        ? widget.initialVehicle!.kmTerakhir ?? 0
        : 0;
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
    final vehicle = widget.initialVehicle;
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
            onPressed: _saveWorkOrder,
            icon: const Icon(Icons.save, color: Colors.green),
            label: const Text('Simpan & Cetak'),
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
              if (vehicle != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        'No. Polisi',
                        vehicle.platNomor,
                        widthLabel,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        'Merk/Tipe',
                        '${vehicle.merk} ${vehicle.tipe}',
                        widthLabel,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow('Warna', vehicle.warna, widthLabel),
                    ),
                    Expanded(
                      child: _buildInfoRow('Tahun', vehicle.tahun, widthLabel),
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

  void _saveWorkOrder() {
    if (_formKey.currentState!.validate() &&
        _selectedVehicle != null &&
        _selectedItems.isNotEmpty) {
      if (_kmController.text.isNotEmpty &&
          (int.tryParse(_kmController.text) ?? 0) >= _kmTerakhir) {
        final wo = WorkOrder(
          noWo: _noWoController.text,
          tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
          vehicleId: _selectedVehicle!.id!,
          mechanicId: _selectedMechanic?.id ?? 0,
          total: _grandTotal,
          status: 'pending',
          catatan: _catatanController.text,
          kmTerakhir: int.tryParse(_kmController.text) ?? 0,
        );
        context.read<WorkOrderCubit>().createWorkOrder(wo, _selectedItems);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simpan data  berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
                  initialValue: _selectedMechanic,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
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
            onPressed: () => _showAddItemDialog(type == 'service'),
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
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() {
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
// class WorkOrderFormScreen extends StatefulWidget {
//   // Menerima parameter opsional kendaraan dari pencarian plat nomor
//   final Vehicle? initialVehicle;

//   const WorkOrderFormScreen({super.key, this.initialVehicle});

//   @override
//   State<WorkOrderFormScreen> createState() => _WorkOrderFormScreenState();
// }

// class _WorkOrderFormScreenState extends State<WorkOrderFormScreen> {
//   final _formKey = GlobalKey<FormState>();

//   // Controllers
//   final TextEditingController _noWoController = TextEditingController();
//   final TextEditingController _catatanController = TextEditingController();
//   final TextEditingController _searchController = TextEditingController();

//   // Data
//   DateTime _selectedDate = DateTime.now();
//   Vehicle? _selectedVehicle;
//   Mechanic? _selectedMechanic;
//   List<WoItem> _selectedItems = [];
//   double _grandTotal = 0.0;

//   // Untuk dialog tambah item
//   bool _isServiceTab = true;
//   List<Service> _filteredServices = [];
//   List<Part> _filteredParts = [];

//   @override
//   void initState() {
//     super.initState();
//     _generateNoWO();

//     // LOGIKA PENTING: Jika ada data kendaraan dari parameter, set ke state
//     if (widget.initialVehicle != null) {
//       _selectedVehicle = widget.initialVehicle;
//     }

//     context.read<VehicleCubit>().loadAll();
//     context.read<MechanicCubit>().loadAll();
//     context.read<ServiceCubit>().loadAll();
//     context.read<PartCubit>().loadAll();
//   }

//   void _generateNoWO() {
//     final uuid = const Uuid().v4().substring(0, 8).toUpperCase();
//     _noWoController.text =
//         "${DateFormat('yyMMddhhmmss').format(DateTime.now())}";
//   }

//   void _updateGrandTotal() {
//     setState(() {
//       _grandTotal = _selectedItems.fold(
//         0.0,
//         (sum, item) => sum + item.subtotal,
//       );
//     });
//   }

//   // ================================== DIALOG TAMBAH ITEM ==================================
  // void _showAddItemDialog() {
  //   _searchController.clear();
  //   _isServiceTab = true;
  //   _loadFilteredItems();

  //   showDialog(
  //     context: context,
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setDialogState) => AlertDialog(
  //         title: const Text('Tambah Jasa / Part'),
  //         content: SizedBox(
  //           width: double.maxFinite,
  //           height: 500,
  //           child: Column(
  //             children: [
  //               SegmentedButton<bool>(
  //                 segments: const [
  //                   ButtonSegment(value: true, label: Text('Jasa')),
  //                   ButtonSegment(value: false, label: Text('Part')),
  //                 ],
  //                 selected: {_isServiceTab},
  //                 onSelectionChanged: (set) {
  //                   setDialogState(() {
  //                     _isServiceTab = set.first;
  //                     _searchController.clear();
  //                     _loadFilteredItems();
  //                   });
  //                 },
  //               ),
  //               const SizedBox(height: 12),
  //               TextField(
  //                 controller: _searchController,
  //                 decoration: const InputDecoration(
  //                   labelText: 'Cari...',
  //                   prefixIcon: Icon(Icons.search),
  //                   border: OutlineInputBorder(),
  //                 ),
  //                 onChanged: (_) => _loadFilteredItems(setDialogState),
  //               ),
  //               const SizedBox(height: 12),
  //               Expanded(
  //                 child: _isServiceTab
  //                     ? _buildServiceList(setDialogState)
  //                     : _buildPartList(setDialogState),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text('Batal'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

//   void _loadFilteredItems([StateSetter? setDialogState]) {
//     final query = _searchController.text.toLowerCase();
//     if (_isServiceTab) {
//       final services = context.read<ServiceCubit>().state is ServiceLoaded
//           ? (context.read<ServiceCubit>().state as ServiceLoaded).services
//           : <Service>[];
//       _filteredServices = services
//           .where((s) => s.nama.toLowerCase().contains(query))
//           .toList();
//     } else {
//       final parts = context.read<PartCubit>().state is PartLoaded
//           ? (context.read<PartCubit>().state as PartLoaded).parts
//           : <Part>[];
//       _filteredParts = parts
//           .where(
//             (p) =>
//                 p.nama.toLowerCase().contains(query) ||
//                 p.kode.toLowerCase().contains(query),
//           )
//           .toList();
//     }
//     if (setDialogState != null) setDialogState(() {});
//   }

//   Widget _buildServiceList(StateSetter setDialogState) {
//     return ListView.builder(
//       itemCount: _filteredServices.length,
//       itemBuilder: (context, index) {
//         final service = _filteredServices[index];
//         return ListTile(
//           title: Text(service.nama),
//           subtitle: Text('Rp ${NumberFormat('#,###').format(service.harga)}'),
//           trailing: const Icon(Icons.add_circle, color: Colors.green),
//           onTap: () {
//             setState(() {
//               _selectedItems.add(
//                 WoItem(
//                   type: 'service',
//                   itemId: service.id!,
//                   namaItem: service.nama,
//                   qty: 1,
//                   harga: service.harga,
//                   subtotal: service.harga,
//                 ),
//               );
//               _updateGrandTotal();
//             });
//             Navigator.pop(context);
//           },
//         );
//       },
//     );
//   }

//   Widget _buildPartList(StateSetter setDialogState) {
//     return ListView.builder(
//       itemCount: _filteredParts.length,
//       itemBuilder: (context, index) {
//         final part = _filteredParts[index];
//         return ListTile(
//           title: Text('${part.kode} - ${part.nama}'),
//           subtitle: Text(
//             'Stok: ${part.stok} | Rp ${NumberFormat('#,###').format(part.hargaJual)}',
//           ),
//           trailing: const Icon(Icons.add_circle, color: Colors.blue),
//           onTap: () {
//             if (part.stok <= 0) {
//               ScaffoldMessenger.of(
//                 context,
//               ).showSnackBar(const SnackBar(content: Text('Stok habis!')));
//               return;
//             }
//             setState(() {
//               _selectedItems.add(
//                 WoItem(
//                   type: 'part',
//                   itemId: part.id!,
//                   namaItem: part.nama,
//                   qty: 1,
//                   harga: part.hargaJual,
//                   subtotal: part.hargaJual,
//                 ),
//               );
//               _updateGrandTotal();
//             });
//             Navigator.pop(context);
//           },
//         );
//       },
//     );
//   }

  // void _saveWorkOrder() {
  //   if (_formKey.currentState!.validate() &&
  //       _selectedVehicle != null &&
  //       _selectedMechanic != null &&
  //       _selectedItems.isNotEmpty) {
  //     final wo = WorkOrder(
  //       noWo: _noWoController.text,
  //       tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
  //       vehicleId: _selectedVehicle!.id!,
  //       mechanicId: _selectedMechanic!.id!,
  //       total: _grandTotal,
  //       status: 'pending',
  //     );
  //     context.read<WorkOrderCubit>().createWorkOrder(wo, _selectedItems);
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Lengkapi data & minimal 1 item')),
  //     );
  //   }
  // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Buat Work Order Baru')),
//       body: MultiBlocListener(
//         listeners: [
//           BlocListener<WorkOrderCubit, WorkOrderState>(
//             listener: (context, state) {
//               if (state is WorkOrderSuccess) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Tersimpan!'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//                 printBilling(
//                   WorkOrder(
//                     noWo: _noWoController.text,
//                     tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
//                     vehicleId: _selectedVehicle?.id ?? 0,
//                     mechanicId: _selectedMechanic?.id ?? 0,
//                     total: _grandTotal,
//                   ),
//                   _selectedItems,
//                 );
//                 Navigator.pop(context);
//               }
//             },
//           ),
//         ],
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 // Field Plat Nomor (Read Only jika dari search)
//                 TextFormField(
//                   controller: _noWoController,
//                   decoration: const InputDecoration(
//                     labelText: 'No. Work Order',
//                     border: OutlineInputBorder(),
//                   ),
//                   readOnly: true,
//                 ),
//                 const SizedBox(height: 16),

//                 // Dropdown Kendaraan
//                 BlocBuilder<VehicleCubit, VehicleState>(
//                   builder: (context, state) {
//                     if (state is VehicleLoaded) {
//                       final v = state.vehicles.firstWhere(
//                         (v) => v.id == _selectedVehicle?.id,
//                       );
//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           // Baris 1: Plat Nomor & Merk (Bold)
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 v.platNomor,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                               Text(
//                                 v.merk,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 4),
//                           // Baris 2: Model, Warna, Tahun (Informasi Lengkap)
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "${v.tipe} (${v.tahun})",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 6,
//                                   vertical: 2,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[200],
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 child: Text(
//                                   v.warna,
//                                   style: const TextStyle(fontSize: 11),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const Divider(height: 1), // Garis pemisah antar item
//                         ],
//                       );
//                     }
//                     return const LinearProgressIndicator();
//                   },
//                 ),
//                 const SizedBox(height: 16),

//                 // Mekanik
//                 BlocBuilder<MechanicCubit, MechanicState>(
//                   builder: (context, state) {
//                     if (state is MechanicLoaded) {
//                       return DropdownButtonFormField<Mechanic>(
//                         value: _selectedMechanic,
//                         decoration: const InputDecoration(
//                           labelText: 'Pilih Mekanik',
//                           border: OutlineInputBorder(),
//                         ),
//                         items: state.mechanics
//                             .map(
//                               (m) => DropdownMenuItem(
//                                 value: m,
//                                 child: Text(m.nama),
//                               ),
//                             )
//                             .toList(),
//                         onChanged: (val) =>
//                             setState(() => _selectedMechanic = val),
//                         validator: (val) =>
//                             val == null ? 'Pilih mekanik' : null,
//                       );
//                     }
//                     return const SizedBox();
//                   },
//                 ),
//                 const SizedBox(height: 24),

//                 ElevatedButton.icon(
//                   onPressed: _showAddItemDialog,
//                   icon: const Icon(Icons.add),
//                   label: const Text('Tambah Jasa / Part'),
//                   style: ElevatedButton.styleFrom(
//                     minimumSize: const Size(double.infinity, 50),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Daftar Item
//                 Container(
//                   height: 200,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: ListView.builder(
//                     itemCount: _selectedItems.length,
//                     itemBuilder: (context, index) {
//                       final item = _selectedItems[index];
//                       return ListTile(
//                         title: Text(item.namaItem),
//                         trailing: Text(
//                           'Rp ${item.subtotal.toStringAsFixed(0)}',
//                         ),
//                         onLongPress: () => setState(() {
//                           _selectedItems.removeAt(index);
//                           _updateGrandTotal();
//                         }),
//                       );
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Total
//                 Text(
//                   'TOTAL: Rp ${_grandTotal.toStringAsFixed(0)}',
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     onPressed: _saveWorkOrder,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text('SIMPAN & CETAK'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _noWoController.dispose();
//     _catatanController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }
// }
