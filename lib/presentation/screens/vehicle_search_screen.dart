import 'package:bengkel/data/repositories/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/vehicle.dart';
import '../blocs/vehicle_cubit.dart';
import 'work_order_form_screen.dart';

class VehicleSearchScreen extends StatefulWidget {
  const VehicleSearchScreen({super.key});

  @override
  State<VehicleSearchScreen> createState() => _VehicleSearchScreenState();
}

class _VehicleSearchScreenState extends State<VehicleSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Vehicle> _displayList = [];

  @override
  void initState() {
    super.initState();
    // Load data awal jika diperlukan
    context.read<VehicleCubit>().loadAll();
  }

  void _filterSearch(String query, List<Vehicle> allVehicles) {
    setState(() {
      _displayList = allVehicles
          .where((v) => v.platNomor.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Kendaraan (Plat Nomor)')),
      body: Column(
        children: [
          // Input Pencarian
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ketik Plat Nomor (Contoh: B 1234 ABC)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _displayList = []);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                final state = context.read<VehicleCubit>().state;
                if (state is VehicleLoaded) {
                  _filterSearch(val, state.vehicles);
                }
              },
            ),
          ),

          // Hasil Pencarian
          Expanded(
            child: BlocBuilder<VehicleCubit, VehicleState>(
              builder: (context, state) {
                if (state is VehicleLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is VehicleLoaded) {
                  // Jika search kosong, tampilkan semua atau instruksi
                  final listToShow = _searchController.text.isEmpty
                      ? state.vehicles
                      : _displayList;

                  if (listToShow.isEmpty) {
                    return const Center(
                      child: Text('Kendaraan tidak ditemukan'),
                    );
                  }

                  return ListView.separated(
                    itemCount: listToShow.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final vehicle = listToShow[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.directions_car),
                        ),
                        title: Text(
                          vehicle.platNomor,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text('${vehicle.merk} ${vehicle.tipe}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          String vehicles = await VehicleRepository()
                              .cekKendaraan(vehicle.id!);
                          // Navigasi ke Form WO dengan data kendaraan terpilih

                          if (vehicles != 'ok') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(vehicles),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkOrderFormScreen(
                                  initialVehicle: vehicle,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                }

                return const Center(child: Text('Gagal memuat data kendaraan'));
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
