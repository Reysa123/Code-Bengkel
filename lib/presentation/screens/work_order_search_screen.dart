import 'package:bengkel/core/database/database_helper.dart';
import 'package:bengkel/data/models/vehicle.dart';
import 'package:bengkel/data/models/work_order.dart';
import 'package:bengkel/data/repositories/work_order_repository.dart';
import 'package:bengkel/presentation/screens/edit_work_order_screen.dart';
import 'package:bengkel/presentation/screens/work_order_detail_screen.dart';
import 'package:bengkel/presentation/screens/work_order_form_screen.dart';
import 'package:flutter/material.dart';

class WorkOrderSearchScreen extends StatefulWidget {
  const WorkOrderSearchScreen({super.key});

  @override
  State<WorkOrderSearchScreen> createState() => _WorkOrderSearchScreenState();
}

class _WorkOrderSearchScreenState extends State<WorkOrderSearchScreen> {
  final TextEditingController searchController = TextEditingController();
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Work Order')),
      body: _buildSearchInput(context),
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Cari No. Work Order...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: InputBorder.none,
            prefixIcon: const Icon(
              Icons.assignment_rounded,
              color: Colors.blueAccent,
            ),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.blueAccent,
              ),
              onPressed: () => _searchWorkOrder(searchController.text, context),
            ),
          ),
          onSubmitted: (val) => _searchWorkOrder(val, context),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String query) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'WO Tidak Ditemukan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Work Order dengan nomor "$query" tidak terdaftar di sistem kami.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Modern look
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Coba Lagi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchWorkOrder(String query, BuildContext context) async {
    if (query.isEmpty) return;

    // Cari di database melalui Cubit/Provider/Repository
    // Misal kita ambil dari database local:
    final List<Map<String, dynamic>> result = await WorkOrderRepository()
        .getAllByWoId(query);

    if (result.isNotEmpty) {
      print(result.toList().toString());
      // Jika ADA, arahkan ke Detail Screen

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditWorkOrderScreen(initialVehicle: result),
        ),
      ).then((onValue) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update data  berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      });
    } else {
      // Jika GAGAL, tampilkan Dialog Modern
      _showErrorDialog(context, query);
    }
  }
}
