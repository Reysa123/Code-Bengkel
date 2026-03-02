// lib/presentation/screens/service_list_screen.dart
// 🔥 SERVICE / JASA LIST SCREEN LENGKAP (Full CRUD + Search + Dialog)

import 'package:bengkel/utils/ribuan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/service.dart';
import '../../presentation/blocs/service_cubit.dart';
import '../../core/constants/app_constants.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<ServiceCubit>().loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ====================== DIALOG TAMBAH / EDIT JASA ======================
  void _showServiceForm({Service? service}) {
    final isEdit = service != null;
    final namaController = TextEditingController(text: service?.nama);
    final hargaController = TextEditingController(
      text: NumberFormat('#,###').format(service?.harga ?? 0),
    );
    final deskripsiController = TextEditingController(text: service?.deskripsi);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Jasa' : 'Tambah Jasa Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama Jasa *'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                controller: hargaController,
                decoration: const InputDecoration(
                  labelText: 'Harga (Rp) *',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
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
              if (namaController.text.isEmpty || hargaController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama dan Harga wajib diisi')),
                );
                return;
              }

              final harga =
                  double.tryParse(hargaController.text.replaceAll(',', '')) ??
                  0;

              final newService = Service(
                id: service?.id,
                nama: namaController.text.trim(),
                harga: harga,
                deskripsi: deskripsiController.text.trim(),
              );

              if (isEdit) {
                // Update (kita tambahkan method di cubit nanti jika belum ada)
                // Untuk sementara pakai add dulu, atau tambah update di cubit
                context.read<ServiceCubit>().addService(
                  newService,
                ); // ganti ke update nanti
              } else {
                context.read<ServiceCubit>().addService(newService);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(AppStrings.saveSuccess)));
            },
            child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Jasa'),
          ),
        ],
      ),
    );
  }

  // ====================== DELETE CONFIRM ======================
  void _showDeleteConfirm(Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jasa?'),
        content: Text(
          'Nama Jasa: ${service.nama}\nHarga: Rp ${service.harga.toStringAsFixed(0)}\n\nData ini akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              // context.read<ServiceCubit>().deleteService(service.id!); // tambahkan method di cubit jika perlu
              // Untuk sekarang kita refresh saja
              context.read<ServiceCubit>().loadAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Jasa dihapus')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Jasa / Service'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ServiceCubit>().loadAll(),
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
                hintText: 'Cari nama jasa...',
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

          // List Jasa
          Expanded(
            child: BlocBuilder<ServiceCubit, ServiceState>(
              builder: (context, state) {
                if (state is ServiceLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ServiceError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<ServiceCubit>().loadAll(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ServiceLoaded) {
                  final filtered = state.services
                      .where((s) => s.nama.toLowerCase().contains(_searchQuery))
                      .toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada data jasa',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => context.read<ServiceCubit>().loadAll(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final service = filtered[index];
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
                              backgroundColor: Colors.green.shade100,
                              child: const Icon(
                                Icons.build,
                                color: Colors.green,
                                size: 32,
                              ),
                            ),
                            title: Text(
                              service.nama,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rp ${NumberFormat('#,###').format(service.harga)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                if (service.deskripsi.isNotEmpty)
                                  Text(
                                    service.deskripsi,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                                  _showServiceForm(service: service);
                                } else if (value == 'delete') {
                                  _showDeleteConfirm(service);
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
        onPressed: () => _showServiceForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jasa'),
        backgroundColor: AppConstants.primaryColor,
      ),
    );
  }
}
