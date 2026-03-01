// lib/presentation/screens/vehicle_list_screen.dart
// 🔥 VEHICLE LIST SCREEN LENGKAP (Full CRUD + Search + Dialog)

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

  void _showVehicleForm({Vehicle? vehicle}) {
    final isEdit = vehicle != null;
    final platController = TextEditingController(text: vehicle?.platNomor);
    final merkController = TextEditingController(text: vehicle?.merk);
    final tipeController = TextEditingController(text: vehicle?.tipe);
    final tahunController = TextEditingController(text: vehicle?.tahun);
    final warnaController = TextEditingController(text: vehicle?.warna);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: platController,
                decoration: const InputDecoration(labelText: 'Plat Nomor *'),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: merkController,
                decoration: const InputDecoration(labelText: 'Merk *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tipeController,
                decoration: const InputDecoration(labelText: 'Tipe *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tahunController,
                decoration: const InputDecoration(labelText: 'Tahun *'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: warnaController,
                decoration: const InputDecoration(labelText: 'Warna'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (platController.text.isEmpty ||
                  merkController.text.isEmpty ||
                  tipeController.text.isEmpty ||
                  tahunController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plat, Merk, Tipe & Tahun wajib diisi')),
                );
                return;
              }

              final newVehicle = Vehicle(
                id: vehicle?.id,
                platNomor: platController.text.trim().toUpperCase(),
                merk: merkController.text.trim(),
                tipe: tipeController.text.trim(),
                tahun: tahunController.text.trim(),
                warna: warnaController.text.trim(),
              );

              if (isEdit) {
                context.read<VehicleCubit>().updateVehicle(newVehicle);
              } else {
                context.read<VehicleCubit>().addVehicle(newVehicle);
              }

              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Kendaraan'),
          ),
        ],
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                          onPressed: () => context.read<VehicleCubit>().loadAll(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is VehicleLoaded) {
                  final filtered = state.vehicles.where((v) {
                    final search = '${v.platNomor} ${v.merk} ${v.tipe}'.toLowerCase();
                    return search.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada data kendaraan', style: TextStyle(fontSize: 16)),
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
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.indigo.shade100,
                              child: Text(
                                vehicle.platNomor.substring(0, 1),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              vehicle.platNomor,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${vehicle.merk} ${vehicle.tipe}'),
                                Text('${vehicle.tahun} • ${vehicle.warna.isEmpty ? "-" : vehicle.warna}'),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')]),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Hapus')]),
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
      ),
    );
  }

  void _showDeleteConfirm(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kendaraan?'),
        content: Text('Plat Nomor: ${vehicle.platNomor}\n\nData ini akan dihapus permanen.'),
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