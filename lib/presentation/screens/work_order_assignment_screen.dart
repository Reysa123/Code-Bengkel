// lib/presentation/screens/work_order_assignment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/work_order.dart';
import '../../data/models/mechanic.dart';
import '../../presentation/blocs/work_order_cubit.dart';
import '../../presentation/blocs/mechanic_cubit.dart';
import '../../data/repositories/work_order_repository.dart';

class WorkOrderAssignmentScreen extends StatefulWidget {
  final WorkOrder workOrder;

  const WorkOrderAssignmentScreen({
    super.key,
    required this.workOrder,
  });

  @override
  State<WorkOrderAssignmentScreen> createState() => _WorkOrderAssignmentScreenState();
}

class _WorkOrderAssignmentScreenState extends State<WorkOrderAssignmentScreen> {
  Mechanic? _selectedMechanic;
  bool _isLoading = false;

  final WorkOrderRepository _woRepo = WorkOrderRepository();

  @override
  void initState() {
    super.initState();
    // Load daftar mekanik
    context.read<MechanicCubit>().loadAll();

    // Optional: pre-select mekanik yang sudah ada (jika WO sudah ditugaskan)
    // Kita bisa fetch nama mekanik nanti via state, atau langsung set ID
    }

  Future<void> _assignMechanic() async {
    if (_selectedMechanic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mekanik terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update hanya kolom mechanic_id & status (jika perlu)
      await _woRepo.updateMechanic(
        widget.workOrder.id!,
        _selectedMechanic!.id!,
        // Optional: ubah status jadi 'in_progress' saat ditugaskan
        // newStatus: 'in_progress',
      );

      // Refresh list WO di cubit (jika ada di halaman sebelumnya)
      if (context.mounted) {
        context.read<WorkOrderCubit>().loadAll();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WO ${widget.workOrder.noWo} berhasil ditugaskan ke ${_selectedMechanic!.nama}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // kembali + beri sinyal sukses
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menugaskan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penugasan Mekanik'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Work Order
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Work Order: ${widget.workOrder.noWo}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Kendaraan: ${widget.workOrder.platNomor ?? "-"} - ${widget.workOrder.merk ?? ""}'),
                    const SizedBox(height: 4),
                    Text('Tanggal: ${widget.workOrder.tanggal}'),
                    const SizedBox(height: 4),
                    Text(
                      'Status saat ini: ${widget.workOrder.status.toUpperCase()}',
                      style: TextStyle(
                        color: _getStatusColor(widget.workOrder.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Pilih Mekanik yang akan menangani',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Dropdown Mekanik
            BlocBuilder<MechanicCubit, MechanicState>(
              builder: (context, state) {
                if (state is MechanicLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MechanicError) {
                  return Text('Gagal memuat mekanik: ${state.message}');
                }

                if (state is MechanicLoaded) {
                  if (state.mechanics.isEmpty) {
                    return const Text(
                      'Belum ada data mekanik. Tambahkan mekanik terlebih dahulu.',
                      style: TextStyle(color: Colors.orange),
                    );
                  }

                  return DropdownButtonFormField<Mechanic>(
                    value: _selectedMechanic,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintText: 'Pilih mekanik...',
                    ),
                    items: state.mechanics.map((mechanic) {
                      return DropdownMenuItem<Mechanic>(
                        value: mechanic,
                        child: Text(mechanic.nama),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedMechanic = value);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            const Spacer(),

            // Tombol Konfirmasi
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _assignMechanic,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.engineering),
                label: Text(
                  _isLoading ? 'Menugaskan...' : 'Tugaskan Mekanik',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
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