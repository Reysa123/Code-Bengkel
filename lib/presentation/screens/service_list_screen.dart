// lib/presentation/screens/service_list_screen.dart

import 'package:bengkel/utils/number_format.dart';
import 'package:bengkel/utils/ribuan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/service.dart';
import '../../presentation/blocs/service_cubit.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();

  // List kategori untuk Dropdown
  final List<String> _categories = [
    ServiceCategory.mesin,
    ServiceCategory.chassis,
    ServiceCategory.electrical,
    ServiceCategory.powertrain,
    ServiceCategory.bodyAndPaint,
    ServiceCategory.generalService,
  ];

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

  // Helper untuk warna chip kategori
  Color _getCategoryColor(String category) {
    switch (category) {
      case ServiceCategory.mesin:
        return Colors.orange;
      case ServiceCategory.chassis:
        return Colors.blue;
      case ServiceCategory.electrical:
        return Colors.purple;
      case ServiceCategory.powertrain:
        return Colors.red;
      case ServiceCategory.bodyAndPaint:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showServiceForm({Service? service}) {
    final isEdit = service != null;
    final namaController = TextEditingController(text: service?.nama);
    final hargaController = TextEditingController(
      text: service != null ? nf.format(service.harga) : '',
    );
    final deskripsiController = TextEditingController(text: service?.deskripsi);
    String selectedKategori =
        service?.kategori ?? ServiceCategory.generalService;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? 'Edit Data Jasa' : 'Tambah Jasa Baru',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input Nama
                    TextFormField(
                      controller: namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Jasa',
                        prefixIcon: const Icon(Icons.build_circle_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama jasa tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Kategori
                    DropdownButtonFormField<String>(
                      initialValue: selectedKategori,
                      decoration: InputDecoration(
                        labelText: 'Kategori Jasa',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _categories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) => selectedKategori = newValue!,
                    ),
                    const SizedBox(height: 16),

                    // Input Harga
                    TextFormField(
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      controller: hargaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga (Rp)',
                        prefixText: 'Rp ',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Harga tidak boleh kosong';
                        }
                        final harga = double.tryParse(
                          value.replaceAll('.', ''),
                        );
                        if (harga == null || harga <= 0) {
                          return 'Harga harus berupa angka positif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Deskripsi
                    TextFormField(
                      controller: deskripsiController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Singkat',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Simpan
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
                          if (_formKey.currentState!.validate()) {
                            final double harga =
                                double.tryParse(
                                  hargaController.text.replaceAll('.', ''),
                                ) ??
                                0;
                            final newService = Service(
                              id: service?.id,
                              nama: namaController.text.trim(),
                              harga: harga,
                              deskripsi: deskripsiController.text.trim(),
                              kategori: selectedKategori,
                            );

                            context.read<ServiceCubit>().addService(newService);
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          isEdit ? 'PERBARUI DATA' : 'SIMPAN JASA',
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
            // 2. Tombol X (Close) di Pojok Kanan Atas
            Positioned(
              right: 0,
              top: 0,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Master Data Jasa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Search Bar Cantik
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari jasa atau kategori...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: BlocBuilder<ServiceCubit, ServiceState>(
              builder: (context, state) {
                if (state is ServiceLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ServiceLoaded) {
                  final filtered = state.services
                      .where(
                        (s) =>
                            s.nama.toLowerCase().contains(_searchQuery) ||
                            s.kategori.toLowerCase().contains(_searchQuery),
                      )
                      .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final service = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service.nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                    service.kategori,
                                  ).withAlpha(5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  service.kategori,
                                  style: TextStyle(
                                    color: _getCategoryColor(service.kategori),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Rp ${nf.format(service.harga)}',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              if (service.deskripsi.isNotEmpty)
                                Text(
                                  service.deskripsi,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_horiz),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showServiceForm(service: service);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text('Belum ada data'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showServiceForm(),
        backgroundColor: Colors.blue.shade800,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'JASA BARU',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
