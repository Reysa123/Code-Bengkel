// ================================================
// 2. lib/presentation/screens/home_screen.dart
// ================================================
import 'package:bengkel/core/constants/app_constants.dart';
import 'package:bengkel/presentation/screens/batalbilling.dart';
import 'package:bengkel/presentation/screens/batalproses.dart';
import 'package:bengkel/presentation/screens/kasir_screen.dart';
import 'package:bengkel/presentation/screens/mechanic_list_screen.dart';
import 'package:bengkel/presentation/screens/neraca_jurnal_screen.dart';
import 'package:bengkel/presentation/screens/part_list_screen.dart';
import 'package:bengkel/presentation/screens/purchse_form_screen.dart';
import 'package:bengkel/presentation/screens/supplier_screen.dart';
import 'package:bengkel/presentation/screens/vehicle_search_screen.dart';
import 'package:bengkel/presentation/screens/work_order_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/work_order_cubit.dart';
import 'work_order_list_screen.dart';
import 'vehicle_list_screen.dart';
import 'service_list_screen.dart';
// import 'part_list_screen.dart';
// import 'mechanic_list_screen.dart';
// import 'supplier_list_screen.dart';
// import 'purchase_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardPage(), // Halaman utama
    const WorkOrderListScreen(), // Daftar Work Order
    const WorkOrderSearchScreen(),
    const VehicleListScreen(), // Data Kendaraan
  ];

  void _onDrawerItemTapped(int index) {
    Navigator.pop(context); // tutup drawer
    if (index == 99) {
      // 99 = Buat Work Order Baru
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VehicleSearchScreen()),
      );
    } else if (index == 1) {
      // 100 = Kasir
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkOrderListScreen()),
      );
    } else if (index == 2) {
      // 2 = Maintenance Work Order
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkOrderSearchScreen()),
      );
    }
  }

  DateTimeRange _currentMonthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final end = nextMonth.subtract(const Duration(milliseconds: 1));
    return DateTimeRange(start: start, end: end);
  }

  @override
  void initState() {
    super.initState();
    context.read<WorkOrderCubit>().loadAll(dateRange: _currentMonthRange());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bengkel Manager Pro'),
        elevation: 0,
        actions: [
          IconButton(
            color: Colors.black,
            tooltip: "Buat Work Order Baru",
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleSearchScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            // Header Drawer
            UserAccountsDrawerHeader(
              accountName: const Text(AppConstants.companyName),
              accountEmail: const Text(AppConstants.companyAddress),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Image.asset(
                  'images/logo.png',
                  width: 60,
                ), // tambah asset sendiri
              ),
              decoration: const BoxDecoration(color: Colors.indigo),
            ),

            // MENU MASTER DATA
            const ListTile(
              leading: Icon(Icons.folder),
              title: Text(
                'MASTER DATA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Data Kendaraan'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleListScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Data Jasa'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServiceListScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Data Part'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PartListScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Data Mekanik'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MechanicListScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Data Supplier'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupplierScreen()),
              ),
            ),

            const Divider(),

            // MENU TRANSAKSI
            const ListTile(
              leading: Icon(Icons.receipt_long),
              title: Text(
                'TRANSAKSI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Buat Work Order Baru'),
              onTap: () => _onDrawerItemTapped(99),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Daftar Work Order'),
              onTap: () => _onDrawerItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.surround_sound_rounded),
              title: const Text('Maintenance Work Order'),
              onTap: () => _onDrawerItemTapped(2),
            ),

            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Pembelian Part'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchaseFormScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('Kasir / Pembayaran'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KasirScreen()),
              ),
            ),

            const Divider(),

            // MENU LAINNYA
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Laporan'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NeracaJurnalScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Pembatalan Pembayaran Kasir'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CancelPaymentSearchPage(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Pembatalan Billing'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UndoFinishWorkOrderSearchPage(),
                ),
              ),
            ),
            //CancelPaymentSearchPage
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan'),
              onTap: () {},
            ),
            const SizedBox(height: 20),
            const ListTile(leading: Icon(Icons.logout), title: Text('Keluar')),
          ],
        ),
      ),
      body: _screens[selectedIndex],
    );
  }
}

// ================================================
// DASHBOARD PAGE (halaman default)
// ================================================
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BlocBuilder<WorkOrderCubit, WorkOrderState>(
        builder: (context, state) {
          if (state is WorkOrderLoaded) {
            final recent = state.workOrders.take(5).toList();
            final totalPendapatan = state.workOrders.fold<double>(
              0,
              (sum, wo) => sum + wo.total,
            );
            final totalKendaraanService = state.workOrders
                .where((wo) => wo.platNomor != null && wo.platNomor!.isNotEmpty)
                .map((wo) => wo.platNomor!)
                .toSet()
                .length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang, Admin!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Quick Stats
                Row(
                  children: [
                    _buildStatCard(
                      'Work Order Bulan Ini',
                      '${state.workOrders.length}',
                      Icons.today,
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Total Pendapatan Bulan Ini',
                      'Rp ${NumberFormat('#,###').format(totalPendapatan)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      'Part Terjual Bulan Ini',
                      '28',
                      Icons.inventory_2,
                      Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Kendaraan Service Bulan Ini',
                      '$totalKendaraanService',
                      Icons.directions_car,
                      Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Text(
                  'Work Order Terbaru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  itemBuilder: (context, i) {
                    final wo = recent[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt),
                        title: Text('WO-${wo.noWo}'),
                        subtitle: Text('${wo.platNomor ?? "—"} • ${wo.status}'),
                        trailing: Text(
                          'Rp ${NumberFormat('#,###').format(wo.total)}',
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(4),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
