// lib/presentation/screens/work_order_list_screen.dart
// 🔥 WORK ORDER LIST SCREEN LENGKAP (Full fitur: search, status badge, print, ubah status, delete)

import 'package:bengkel/presentation/screens/billing_screen.dart';
import 'package:bengkel/presentation/screens/edit_work_order_screen.dart';
import 'package:bengkel/presentation/screens/vehicle_search_screen.dart';
import 'package:bengkel/presentation/screens/work_order_assignment_screen.dart';
import 'package:bengkel/presentation/screens/work_order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/work_order.dart';
import '../../data/repositories/work_order_repository.dart';
import '../../presentation/blocs/work_order_cubit.dart';

class WorkOrderListScreen extends StatefulWidget {
  const WorkOrderListScreen({super.key});

  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final WorkOrderRepository _repository = WorkOrderRepository();
  DateTime _selectedMonth = DateTime.now();
  DateTimeRange? _dateRange;
  @override
  void initState() {
    super.initState();
    context.read<WorkOrderCubit>().loadAll();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    // Default: load bulan ini
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    context.read<WorkOrderCubit>().loadAll(
      dateRange: DateTimeRange(start: start, end: end),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter periode tampilan
  String get periodText {
    if (_dateRange != null) {
      return '${DateFormat('d MMM').format(_dateRange!.start)} – '
          '${DateFormat('d MMM yyyy').format(_dateRange!.end)}';
    }
    return DateFormat('MMMM yyyy').format(_selectedMonth);
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _dateRange = null;
      });
      // Default: load bulan ini
      final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      context.read<WorkOrderCubit>().loadAll(
        dateRange: DateTimeRange(start: start, end: end),
      );
    }
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (range != null && mounted) {
      setState(() => _dateRange = range);
      context.read<WorkOrderCubit>().loadAll(dateRange: range); // refresh
    }
  }

  // ====================== PRINT ======================
  Future<void> _printWorkOrder(WorkOrder wo) async {
    // Catatan: Untuk print lengkap dengan item, fetch wo_items dulu (bisa dikembangkan)
    // Untuk sekarang print header + total
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mencetak Work Order...')));
    // await printBilling(wo, []); // kosong dulu, nanti bisa di-improve
  }

  // ====================== UBAH STATUS ======================
  Future<void> _updateStatus(WorkOrder wo, String newStatus) async {
    double paid = wo.paid;
    if (newStatus == 'paid') paid = wo.total;

    await _repository.updateStatus(wo.id!, newStatus, paid);
     if (!mounted) return;
    await context.read<WorkOrderCubit>().loadAll();
 if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status diubah menjadi ${newStatus.toUpperCase()}'),
      ),
    );
  }

  // ====================== DELETE ======================

  // ====================== STATUS COLOR ======================
  Color _getStatusColor(String status) {
    switch (status) {
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'on_progress':
        return 'Sedang Dikerjakan';
      case 'completed':
        return 'Selesai';
      case 'paid':
        return 'Lunas';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Work Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<WorkOrderCubit>().loadAll(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          // Filter Periode & Search
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: Text(
                          periodText,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.indigo),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _pickMonth,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range, size: 18),
                      label: const Text(
                        'Rentang',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.indigo),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _pickDateRange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari No WO atau Plat Nomor...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                ),
              ],
            ),
          ),
          // List Work Order
          Expanded(
            child: BlocBuilder<WorkOrderCubit, WorkOrderState>(
              builder: (context, state) {
                if (state is WorkOrderLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is WorkOrderError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<WorkOrderCubit>().loadAll(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is WorkOrderLoaded) {
                  var filtered = state.workOrders.where((wo) {
                    final searchText =
                        '${wo.noWo} ${wo.platNomor ?? ""} ${wo.merk ?? ""}'
                            .toLowerCase();
                    return searchText.contains(_searchQuery);
                  }).toList();
                  // Filter tanggal jika ada
                  if (_dateRange != null) {
                    filtered = filtered.where((wo) {
                      try {
                        final woDate = DateFormat(
                          'yyyy-MM-dd',
                        ).parse(wo.tanggal);
                        return woDate.isAfter(
                              _dateRange!.start.subtract(
                                const Duration(days: 1),
                              ),
                            ) &&
                            woDate.isBefore(
                              _dateRange!.end.add(const Duration(days: 1)),
                            );
                      } catch (e) {
                        return true; // jika format tanggal salah, tetap tampilkan
                      }
                    }).toList();
                  } else {
                    // Default bulan ini
                    final startOfMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month,
                      1,
                    );
                    final endOfMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                      0,
                    );
                    filtered = filtered.where((wo) {
                      try {
                        final woDate = DateFormat(
                          'yyyy-MM-dd',
                        ).parse(wo.tanggal);
                        return woDate.isAfter(
                              startOfMonth.subtract(const Duration(days: 1)),
                            ) &&
                            woDate.isBefore(
                              endOfMonth.add(const Duration(days: 1)),
                            );
                      } catch (e) {
                        return true;
                      }
                    }).toList();
                  }
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada Work Order',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => context.read<WorkOrderCubit>().loadAll(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final wo = filtered[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      wo.noWo,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Chip(
                                      label: Text(_getStatusLabel(wo.status)),
                                      backgroundColor: _getStatusColor(
                                        wo.status,
                                      ).withAlpha(50),
                                      labelStyle: TextStyle(
                                        color: _getStatusColor(wo.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Text('Tanggal : ${wo.tanggal}'),
                                Text(
                                  'Kendaraan : ${wo.platNomor ?? "-"} - ${wo.merk ?? ""}',
                                ),
                                Text('Mekanik   : ${wo.namaMekanik ?? "-"}'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rp ${NumberFormat('#,###').format(wo.total)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.print,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () => _printWorkOrder(wo),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert),
                                          onSelected: (value) async {
                                            if (value == 'status') {
                                              _showStatusDialog(wo);
                                            } else if (value == 'cetakpart') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      WorkOrderDetailScreen(
                                                        workOrder: wo,
                                                      ),
                                                ),
                                              );
                                            } else if (value == 'addmekanik') {
                                              // Navigasi ke screen penambahan mekanik
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      WorkOrderAssignmentScreen(
                                                        workOrder: wo,
                                                      ),
                                                ),
                                              );
                                            } else if (value == 'cetakbill') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => BillingScreen(
                                                    workOrder: wo,
                                                  ),
                                                ),
                                              );
                                            } else if (value == 'complete') {
                                              if (wo.status == 'pending') {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    content: Text(
                                                      'WO belum dikerjakan atau belum assigned mekanik.',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              if (wo.status == 'completed' ||
                                                  wo.status == 'paid' ||
                                                  wo.status == 'finished') {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    content: Text(
                                                      'WO sudah selesai.',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              List<String> d = [];
                                              var s =
                                                  await WorkOrderRepository()
                                                      .getAllByWoId(wo.noWo);
                                                      
                                              for (var e in s) {
                                                if (e['type'] == 'part') {
                                                  d.add(e['status_item']);
                                                }
                                              }
                                              if (d.contains('pending') ||
                                                  d.contains('on_progress')) {
                                                    
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    content: Text(
                                                      'WO belum dikerjakan atau belum cetak part.',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                               
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text(
                                                    'Selesaikan Work Order?',
                                                  ),
                                                  content: const Text(
                                                    'Pastikan semua pekerjaan sudah selesai dan part sudah dicetak sebelum menyelesaikan WO.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                      child: const Text(
                                                        'Batal',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        await _repository
                                                            .completedWorkOrder(
                                                              (wo.noWo),
                                                            );
                                                        await context
                                                            .read<
                                                              WorkOrderCubit
                                                            >()
                                                            .loadAll();
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Work Order diselesaikan',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.green,
                                                          ),
                                                      child: const Text(
                                                        'Selesaikan',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else if (value == 'maintancewo') {
                                              // Navigasi ke screen maintenance WO
                                              final List<Map<String, dynamic>>
                                              result =
                                                  await WorkOrderRepository()
                                                      .getAllByWoId(wo.noWo);
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EditWorkOrderScreen(
                                                        initialVehicle: result,
                                                      ),
                                                ),
                                              ).then((onValue) {
                                                if (onValue == true) {
                                                  // Jika data berhasil diupdate, tampilkan SnackBar sukses
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Update data  berhasil!',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                }
                                                return;
                                              });
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'status',
                                              child: Text('Ubah Status'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'maintancewo',
                                              child: Text('Maintenance WO'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'addmekanik',
                                              child: Text('Tambah Mekanik'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'cetakpart',
                                              child: Text('Cetak Part'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'complete',
                                              child: Text('Komplit WO'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'cetakbill',
                                              child: Text('Cetak Billing'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                return const Center(child: Text('Belum ada Work Order'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VehicleSearchScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Work Order Baru'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Dialog Ubah Status
  void _showStatusDialog(WorkOrder wo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Status Work Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Pending'),
              leading: const Icon(Icons.hourglass_empty, color: Colors.orange),
              onTap: () {
                _updateStatus(wo, 'pending');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Sedang Dikerjakan'),
              leading: const Icon(Icons.build, color: Colors.blue),
              onTap: () {
                _updateStatus(wo, 'on_progress');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Selesai'),
              leading: const Icon(Icons.check_circle, color: Colors.green),
              onTap: () {
                _updateStatus(wo, 'completed');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Lunas'),
              leading: const Icon(Icons.paid, color: Colors.purple),
              onTap: () {
                _updateStatus(wo, 'paid');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
