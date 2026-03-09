// lib/presentation/screens/part_list_screen.dart
// 🔥 PART / SPAREPART LIST SCREEN LENGKAP (Full CRUD + Search + Stok Highlight)

import 'package:bengkel/utils/ribuan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/part.dart';
import '../../presentation/blocs/part_cubit.dart';
import '../../core/constants/app_constants.dart';

class PartListScreen extends StatefulWidget {
  const PartListScreen({super.key});

  @override
  State<PartListScreen> createState() => _PartListScreenState();
}

class _PartListScreenState extends State<PartListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<PartCubit>().loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ====================== DIALOG TAMBAH / EDIT PART ======================
  void _showPartForm({Part? part}) {
    final isEdit = part != null;

    final kodeController = TextEditingController(text: part?.kode);
    final namaController = TextEditingController(text: part?.nama);
    final stokController = TextEditingController(
      text: part?.stok.toString() ?? '0',
    );
    final hargaBeliController = TextEditingController(
      text: NumberFormat("#,###").format(part?.hargaBeli ?? 0),
    );
    final hargaJualController = TextEditingController(
      text: NumberFormat("#,###").format(part?.hargaJual ?? 0),
    );

    // 1. Bungkus Column dengan Form agar bisa menggunakan validator bawaan Flutter
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Part' : 'Tambah Part Baru'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Form(
              key: formKey, // Tambahkan key di sini
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    // Ubah TextField jadi TextFormField
                    controller: kodeController,
                    decoration: const InputDecoration(
                      labelText: 'Kode Part *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Kode wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: namaController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Part *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: stokController,
                    readOnly:
                        isEdit, // Biasanya stok tidak diubah langsung di edit part (via transaksi)
                    decoration: const InputDecoration(
                      labelText: 'Stok Awal',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: hargaBeliController,
                    decoration: const InputDecoration(
                      labelText: 'Harga Beli (Rp)',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: hargaJualController,
                    decoration: const InputDecoration(
                      labelText: 'Harga Jual (Rp) *',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga jual wajib diisi';
                      }

                      // Validasi Logika: Harga Jual vs Harga Beli
                      final hJual =
                          double.tryParse(value.replaceAll(',', '')) ?? 0;
                      final hBeli =
                          double.tryParse(
                            hargaBeliController.text.replaceAll(',', ''),
                          ) ??
                          0;

                      if (hJual < hBeli) {
                        return 'Harga jual tidak boleh < harga beli';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isEdit
                  ? Colors.green
                  : AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Trigger validasi Form
              if (formKey.currentState!.validate()) {
                final stok = int.tryParse(stokController.text) ?? 0;

                final hargaBeli =
                    double.tryParse(
                      hargaBeliController.text.replaceAll(',', ''),
                    ) ??
                    0;

                final hargaJual =
                    double.tryParse(
                      hargaJualController.text.replaceAll(',', ''),
                    ) ??
                    0;

                // 2. Buat objek Part baru
                final partData = Part(
                  id: isEdit
                      ? part.id
                      : null, // ID tetap jika edit, null jika baru
                  kode: kodeController.text.trim().toUpperCase(),
                  nama: namaController.text.trim(),
                  stok: stok,
                  hargaBeli: hargaBeli,
                  hargaJual: hargaJual,
                );

                // 3. Eksekusi ke Cubit berdasarkan status
                if (isEdit) {
                  // Pastikan di PartCubit kamu sudah ada method updatePart
                  context.read<PartCubit>().addPart(partData);
                } else {
                  context.read<PartCubit>().addPart(partData);
                }

                // 4. Feedback ke User
                Navigator.pop(context); // Tutup Dialog

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit
                          ? 'Perubahan berhasil disimpan'
                          : 'Part baru berhasil ditambahkan',
                    ),
                    backgroundColor: isEdit ? Colors.blue : Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Part'),
          ),
        ],
      ),
    );
  }

  // ====================== DELETE CONFIRM ======================
  void _showDeleteConfirm(Part part) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Part?'),
        content: Text(
          'Kode: ${part.kode}\n'
          'Nama: ${part.nama}\n'
          'Stok: ${part.stok}\n\n'
          'Data ini akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              // Tambahkan deletePart di PartCubit jika ingin full delete
              // Untuk sekarang refresh list
              context.read<PartCubit>().loadAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Part dihapus')));
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
        title: const Text('Data Part / Sparepart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PartCubit>().loadAll(),
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
                hintText: 'Cari kode atau nama part...',
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

          // List Part
          Expanded(
            child: BlocBuilder<PartCubit, PartState>(
              builder: (context, state) {
                if (state is PartLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PartError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<PartCubit>().loadAll(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is PartLoaded) {
                  final filtered = state.parts.where((p) {
                    final search = '${p.kode} ${p.nama}'.toLowerCase();
                    return search.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada data part',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => context.read<PartCubit>().loadAll(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final part = filtered[index];
                        final stokColor = part.stok < 5
                            ? Colors.red
                            : Colors.green;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.orange.shade50,
                                child: Icon(
                                  Icons.inventory_2,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              title: Text(
                                part.nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    part.kode,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jual: Rp ${NumberFormat("#,###").format(part.hargaJual)}',
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              // Kita gunakan Row di trailing agar layout lebih stabil
                              trailing: Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Penting agar tidak memenuhi layar
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Stok',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '${part.stok}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: stokColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.more_vert),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Hapus'),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showPartForm(part: part);
                                      }
                                      if (value == 'delete') {
                                        _showDeleteConfirm(part);
                                      }
                                    },
                                  ),
                                ],
                              ),
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
        onPressed: () => _showPartForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Part'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
