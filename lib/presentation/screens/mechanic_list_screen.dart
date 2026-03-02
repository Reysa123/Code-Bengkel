// lib/presentation/screens/mechanic_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/mechanic.dart';
import '../../presentation/blocs/mechanic_cubit.dart';
import '../../core/constants/app_constants.dart';

class MechanicListScreen extends StatefulWidget {
  const MechanicListScreen({super.key});

  @override
  State<MechanicListScreen> createState() => _MechanicListScreenState();
}

class _MechanicListScreenState extends State<MechanicListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<MechanicCubit>().loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =====================================================
  // Dialog Tambah / Edit Mekanik
  // =====================================================
  void _showMechanicForm({Mechanic? mechanic}) {
    final isEdit = mechanic != null;

    final namaController = TextEditingController(text: mechanic?.nama);
    final noHpController = TextEditingController(text: mechanic?.noHp);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Mekanik' : 'Tambah Mekanik Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap *',
                  hintText: 'Contoh: Wayan Susila',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noHpController,
                decoration: const InputDecoration(
                  labelText: 'Nomor HP / WhatsApp',
                  hintText: 'Contoh: 081234567890',
                  prefixText: '+62 ',
                ),
                keyboardType: TextInputType.phone,
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
              if (namaController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama mekanik wajib diisi')),
                );
                return;
              }

              final newMechanic = Mechanic(
                id: mechanic?.id,
                nama: namaController.text.trim(),
                noHp: noHpController.text.trim().isEmpty
                    ? "0"
                    : noHpController.text.trim(),
              );

              if (isEdit) {
                // Jika sudah punya method update di cubit, panggil di sini
                // Untuk sementara pakai add (kamu bisa ganti nanti)
                context.read<MechanicCubit>().updateMechanic(newMechanic);
              } else {
                context.read<MechanicCubit>().addMechanic(newMechanic);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data mekanik berhasil disimpan'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Mekanik'),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Konfirmasi Hapus
  // =====================================================
  void _showDeleteConfirm(Mechanic mechanic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Mekanik?'),
        content: Text(
          'Nama: ${mechanic.nama}\n'
          '${"No HP: ${mechanic.noHp}"}\n\n'
          'Data ini akan dihapus permanen.\n'
          'Pastikan mekanik ini tidak sedang menangani work order aktif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              // Jika sudah punya method delete di cubit
              context.read<MechanicCubit>().deleteMechanic(mechanic.id!);
              // Untuk sekarang hanya refresh
              context.read<MechanicCubit>().loadAll();

              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Mekanik dihapus')));
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
        title: const Text('Data Mekanik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MechanicCubit>().loadAll(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama mekanik atau nomor HP...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Daftar mekanik
          Expanded(
            child: BlocBuilder<MechanicCubit, MechanicState>(
              builder: (context, state) {
                if (state is MechanicLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MechanicError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text('Terjadi kesalahan: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.read<MechanicCubit>().loadAll(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is MechanicLoaded) {
                  final filtered = state.mechanics.where((m) {
                    final searchText = '${m.nama} ${m.noHp}'.toLowerCase();
                    return searchText.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada data mekanik',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => context.read<MechanicCubit>().loadAll(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final mechanic = filtered[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                mechanic.nama.isNotEmpty
                                    ? mechanic.nama[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            title: Text(
                              mechanic.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: mechanic.noHp.isNotEmpty
                                ? Text(
                                    mechanic.noHp,
                                    style: TextStyle(color: Colors.grey[700]),
                                  )
                                : const Text(
                                    'Tidak ada nomor HP',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showMechanicForm(mechanic: mechanic);
                                } else if (value == 'delete') {
                                  _showDeleteConfirm(mechanic);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 12),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                return const Center(child: Text('Tidak ada data'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMechanicForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Mekanik'),
        backgroundColor: AppConstants.primaryColor,
      ),
    );
  }
}
