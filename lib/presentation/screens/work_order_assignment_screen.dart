// lib/presentation/screens/work_order_assignment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/work_order.dart';
import '../../data/models/mechanic.dart';
import '../../presentation/blocs/work_order_cubit.dart';
import '../../presentation/blocs/mechanic_cubit.dart';
import '../../data/repositories/work_order_repository.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<MechanicCubit>().loadAll();

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
        widget.workOrder.id!,
        mechanicIds,
        // Optional: newStatus: 'in_progress'
      );

      if (context.mounted) {
        context.read<WorkOrderCubit>().loadAll();
      }

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
    showDialog(
      context: context,
      builder: (context) {
        final availableMechanics =
            (context.read<MechanicCubit>().state as MechanicLoaded?)
                ?.mechanics ??
            [];

        return AlertDialog(
          title: const Text('Pilih Mekanik'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: availableMechanics.length,
              itemBuilder: (context, index) {
                final mechanic = availableMechanics[index];
                final isSelected = selectedMechanics.contains(mechanic);

                return CheckboxListTile(
                  title: Text(mechanic.nama),
                  subtitle: mechanic.noHp != null ? Text(mechanic.noHp!) : null,
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedMechanics.add(mechanic);
                      } else {
                        selectedMechanics.remove(mechanic);
                      }
                    });
                  },
                  activeColor: Colors.blue.shade700,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {}); // refresh UI chips
                Navigator.pop(context);
              },
              child: const Text('Simpan Pilihan'),
            ),
          ],
        );
      },
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
                  onPressed: _showSelectMechanicsDialog,
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
                onPressed: _isLoading || selectedMechanics.isEmpty
                    ? null
                    : _assignMechanics,
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
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'paid':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
