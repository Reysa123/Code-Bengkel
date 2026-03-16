// lib/presentation/screens/work_order_assignment_screen.dart

import 'package:bengkel/data/repositories/mechanic_repository.dart';
import 'package:bengkel/data/repositories/work_order_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/work_order.dart';
import '../../data/models/mechanic.dart';
import '../../presentation/blocs/work_order_cubit.dart';
import '../../presentation/blocs/mechanic_cubit.dart';

class WorkOrderAssignmentScreen extends StatefulWidget {
  final WorkOrder workOrder;

  const WorkOrderAssignmentScreen({super.key, required this.workOrder});

  @override
  State<WorkOrderAssignmentScreen> createState() =>
      _WorkOrderAssignmentScreenState();
}

class _WorkOrderAssignmentScreenState extends State<WorkOrderAssignmentScreen> {
  List<Mechanic> selectedMechanics = [];
  bool _isLoading = false;
  final WorkOrderRepository _woRepo = WorkOrderRepository();
  final MechanicRepository _meRepo = MechanicRepository();
  cek() async {
    final assignedMechanics = await _meRepo.getAll();
    setState(() {
      selectedMechanics = assignedMechanics
          .where((v) => v.id == widget.workOrder.mechanicId)
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<MechanicCubit>().loadAll();
    cek();
    // Pre-select mekanik yang sudah ditugaskan (jika ada data dari join sebelumnya)
    // Misalnya: jika WorkOrder sudah punya list assignedMechanics dari repository
    // Untuk sekarang kita kosongkan dulu, atau ambil dari state jika sudah diimplementasikan
  }

  Future<void> _assignMechanics() async {
    if (selectedMechanics.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 mekanik')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final mechanicIds = selectedMechanics.map((m) => m.id!).toList();
      // Panggil repository untuk assign multiple mechanics
      await _woRepo.assignMechanics(
        widget.workOrder.noWo,
        mechanicIds,
        // Optional: newStatus: 'on_progress'
      );

      if (!mounted) return;
        context.read<WorkOrderCubit>().loadAll();
      

      if (context.mounted) {
        final mechanicNames = selectedMechanics.map((m) => m.nama).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'WO ${widget.workOrder.noWo} ditugaskan ke: $mechanicNames',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menugaskan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSelectMechanicsDialog() {
    // Pastikan data mekanik sudah dimuat sebelum dialog muncul
    if (context.read<MechanicCubit>().state is! MechanicLoaded) {
      context.read<MechanicCubit>().loadAll();
      // Optional: tampilkan loading sementara
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Memuat daftar mekanik...')));
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStates) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.engineering, color: Colors.indigo),
                const SizedBox(width: 12),
                const Text(
                  'Pilih Mekanik',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 320, // beri ruang lebih agar tidak terlalu sempit
              child: BlocBuilder<MechanicCubit, MechanicState>(
                builder: (context, state) {
                  if (state is MechanicLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is MechanicError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Gagal memuat: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<MechanicCubit>().loadAll(),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is MechanicLoaded) {
                    final availableMechanics = state.mechanics;

                    if (availableMechanics.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada data mekanik.\nTambahkan mekanik terlebih dahulu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: availableMechanics.length,
                      itemBuilder: (context, index) {
                        final mechanic = availableMechanics[index];
                        bool isSelected = selectedMechanics.contains(mechanic);

                        return CheckboxListTile(
                          title: Text(
                            mechanic.nama,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: mechanic.noHp.isNotEmpty
                              ? Text(
                                  mechanic.noHp,
                                  style: TextStyle(color: Colors.grey.shade700),
                                )
                              : null,
                          secondary: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(
                              mechanic.nama.isNotEmpty
                                  ? mechanic.nama[0].toUpperCase()
                                  : '?',
                              style: TextStyle(color: Colors.indigo.shade700),
                            ),
                          ),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (!selectedMechanics.contains(mechanic)) {
                                  selectedMechanics.add(mechanic);
                                  setStates(() {
                                    isSelected = selectedMechanics.contains(
                                      mechanic,
                                    );
                                  }); // refresh dialog
                                }
                              } else {
                                selectedMechanics.remove(mechanic);
                                setStates(() {
                                  isSelected = selectedMechanics.contains(
                                    mechanic,
                                  );
                                });
                              }
                            });
                          },
                          activeColor: Colors.indigo,
                          checkColor: Colors.white,
                        );
                      },
                    );
                  }

                  return const Center(child: Text('Tidak ada data'));
                },
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {}); // refresh chips di layar utama
                  Navigator.pop(dialogContext);
                },
                child: const Text('Simpan Pilihan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penugasan Mekanik'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Info Work Order + Kendaraan
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.indigo,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Work Order: ${widget.workOrder.noWo}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.directions_car,
                      'Kendaraan',
                      widget.workOrder.platNomor ?? "-",
                    ),
                    _buildInfoRow(
                      Icons.branding_watermark,
                      'Merk & Tipe',
                      '${widget.workOrder.merk ?? "-"} ${widget.workOrder.tipe ?? ""}',
                    ),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Tahun',
                      widget.workOrder.tahun.toString(),
                    ),
                    _buildInfoRow(
                      Icons.palette,
                      'Warna',
                      widget.workOrder.warna ?? "-",
                    ),
                    _buildInfoRow(
                      Icons.person,
                      'Customer',
                      widget.workOrder.namaCustomer ?? "-",
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${widget.workOrder.status.toUpperCase()}',
                          style: TextStyle(
                            color: _getStatusColor(widget.workOrder.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section Mekanik
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mekanik yang Ditugaskan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed:
                      widget.workOrder.status == 'pending' ||
                          widget.workOrder.status == 'on_progress'
                      ? _showSelectMechanicsDialog
                      : null,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Tambah / Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Chips Mekanik Terpilih
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedMechanics.isEmpty
                  ? [
                      const Chip(
                        label: Text(
                          'Belum ada mekanik ditugaskan',
                          style: TextStyle(color: Colors.grey),
                        ),
                        backgroundColor: Colors.grey,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ]
                  : selectedMechanics.map((mechanic) {
                      return Chip(
                        label: Text(mechanic.nama),
                        avatar: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            mechanic.nama.isNotEmpty
                                ? mechanic.nama[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.indigo),
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            selectedMechanics.remove(mechanic);
                          });
                        },
                        backgroundColor: Colors.indigo.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
            ),

            const SizedBox(height: 32),

            // Tombol Konfirmasi
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed:
                    widget.workOrder.status == 'pending' ||
                        widget.workOrder.status == 'on_progress'
                    ? _isLoading || selectedMechanics.isEmpty
                          ? null
                          : _assignMechanics
                    : null,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.engineering_rounded),
                label: Text(
                  _isLoading ? 'Menugaskan...' : 'Tugaskan Mekanik',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'on_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'finished':
        return Colors.red.shade200;
      case 'paid':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
