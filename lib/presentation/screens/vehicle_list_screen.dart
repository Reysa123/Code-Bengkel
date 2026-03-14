// lib/presentation/screens/vehicle_list_screen.dart
// 🔥 VEHICLE LIST SCREEN LENGKAP (Full CRUD + Search + Dialog)

import 'package:bengkel/data/models/customer.dart';
import 'package:bengkel/presentation/blocs/customer_cubit.dart';
import 'package:bengkel/presentation/blocs/customer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/vehicle.dart';
import '../../presentation/blocs/vehicle_cubit.dart';
import '../../core/constants/app_constants.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<VehicleCubit>().loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCustomerPicker({required Function(Customer) onSelected}) {
    String searchC = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          // Menggunakan Dialog standar untuk kontrol penuh layout
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Pilih Customer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari nama customer...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (v) =>
                          setDialogState(() => searchC = v.toLowerCase()),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: BlocBuilder<CustomerCubit, CustomerState>(
                        builder: (context, state) {
                          if (state is CustomerLoaded) {
                            final filtered = state.customers
                                .where(
                                  (c) => c.nama.toLowerCase().contains(searchC),
                                )
                                .toList();

                            if (filtered.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('Customer tidak ditemukan'),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) => ListTile(
                                title: Text(
                                  filtered[i].nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(filtered[i].noHp.toString()),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                ),
                                onTap: () {
                                  onSelected(filtered[i]);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('TAMBAH CUSTOMER BARU'),
                        onPressed: () {
                          Navigator.pop(context); // Tutup picker
                          _showNewCustomerForm(
                            onSuccess: onSelected,
                          ); // Buka form input
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Tombol X di Pojok Kanan Atas
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVehicleForm({Vehicle? vehicle}) {
    final isEdit = vehicle != null;
    final formKey = GlobalKey<FormState>();

    // Inisialisasi ID customer jika sedang edit
    int? selectedCustomerId = vehicle?.customerId;

    final platController = TextEditingController(text: vehicle?.platNomor);
    final noraController = TextEditingController(text: vehicle?.nora);
    final merkController = TextEditingController(text: vehicle?.merk);
    final tipeController = TextEditingController(text: vehicle?.tipe);
    final tahunController = TextEditingController(text: vehicle?.tahun);
    final warnaController = TextEditingController(text: vehicle?.warna);
    // Tampilkan nama customer jika ada data kendaraan (perlu field namaCustomer di model Vehicle)
    final customerController = TextEditingController(
      text: vehicle?.namaCustomer ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        // Agar UI internal BottomSheet bisa update (setState)
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 12,
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Text(
                        isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan Baru',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        autofocus: true,
                        controller: platController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Plat Nomor *',
                          prefixIcon: const Icon(Icons.pin_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: noraController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Nomor Rangka *',
                          prefixIcon: const Icon(Icons.pin_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: merkController,
                              decoration: InputDecoration(
                                labelText: 'Merk *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? 'Wajib' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: tipeController,
                              decoration: InputDecoration(
                                labelText: 'Tipe *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? 'Wajib' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: tahunController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Tahun *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? 'Wajib' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: warnaController,
                              decoration: InputDecoration(
                                labelText: 'Warna',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // FIELD CUSTOMER
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: customerController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Pemilik / Customer *',
                                prefixIcon: const Icon(Icons.person_outline),
                                hintText: 'Pilih Customer...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Pilih pemilik' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 58,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                foregroundColor: Colors.blue.shade800,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.blue.shade100),
                                ),
                              ),
                              onPressed: () => _showCustomerPicker(
                                onSelected: (customer) {
                                  setSheetState(() {
                                    // Gunakan setSheetState dari StatefulBuilder
                                    customerController.text = customer.nama;
                                    selectedCustomerId = customer.id;
                                  });
                                },
                              ),
                              child: const Icon(Icons.person_search),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // TOMBOL SIMPAN (Pindah ke sini karena BottomSheet tidak punya properti 'actions')
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final newVehicle = Vehicle(
                                id: vehicle?.id,
                                customerId:
                                    selectedCustomerId, // Simpan ID Relasi
                                platNomor: platController.text
                                    .trim()
                                    .toUpperCase(),
                                nora: noraController.text.trim().toUpperCase(),
                                merk: merkController.text.trim(),
                                tipe: tipeController.text.trim(),
                                tahun: tahunController.text.trim(),
                                warna: warnaController.text.trim(),
                              );

                              if (isEdit) {
                                context.read<VehicleCubit>().updateVehicle(
                                  newVehicle,
                                );
                              } else {
                                context.read<VehicleCubit>().addVehicle(
                                  newVehicle,
                                );
                              }
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAH KENDARAAN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Tombol X Close
              Positioned(
                right: -10,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tambahkan fungsi ini agar _showCustomerPicker tidak error
  void _showNewCustomerForm({required Function(Customer) onSuccess}) {
    final formKey = GlobalKey<FormState>();
    final nameC = TextEditingController();
    final almtC = TextEditingController();
    final phoneC = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // User harus tekan tombol atau X
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tambah Customer Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameC,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneC,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor HP *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Nomor HP wajib diisi';
                          if (v.length < 10) return 'Nomor tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: almtC,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Alamat (Opsional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (v) {
                          if (v != null && v.isEmpty) {
                            return 'Alamat tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final newCust = Customer(
                                nama: nameC.text.trim(),
                                noHp: phoneC.text.trim(),
                                alamat: almtC.text.trim(),
                              );

                              // Tampilkan loading sebentar
                              final result = await context
                                  .read<CustomerCubit>()
                                  .addCustomer(newCust);

                              if (result != null) {
                                onSuccess(result);
                                if (context.mounted) Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Customer berhasil ditambahkan',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('SIMPAN CUSTOMER'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tombol X di Pojok Kanan Atas
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Kendaraan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<VehicleCubit>().loadAll(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari plat nomor atau merk...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // List
          Expanded(
            child: BlocBuilder<VehicleCubit, VehicleState>(
              builder: (context, state) {
                if (state is VehicleLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is VehicleError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<VehicleCubit>().loadAll(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is VehicleLoaded) {
                  final filtered = state.vehicles.where((v) {
                    final search = '${v.platNomor} ${v.merk} ${v.tipe}'
                        .toLowerCase();
                    return search.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada data kendaraan',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => context.read<VehicleCubit>().loadAll(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final vehicle = filtered[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.indigo.shade100,
                              child: Text(
                                vehicle.platNomor.substring(0, 1),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              vehicle.platNomor,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${vehicle.merk} ${vehicle.tipe}'),
                                Text(
                                  '${vehicle.tahun} • ${vehicle.warna.isEmpty ? "-" : vehicle.warna}',
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Hapus'),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showVehicleForm(vehicle: vehicle);
                                } else if (value == 'delete') {
                                  _showDeleteConfirm(vehicle);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                return const Center(child: Text(AppStrings.noData));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVehicleForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kendaraan'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showDeleteConfirm(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kendaraan?'),
        content: Text(
          'Plat Nomor: ${vehicle.platNomor}\n\nData ini akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<VehicleCubit>().deleteVehicle(vehicle.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kendaraan dihapus')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
