import 'package:bengkel/data/models/jurnalumum.dart';
import 'package:bengkel/data/repositories/accounting_repository.dart';
import 'package:bengkel/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NeracaJurnalScreen extends StatefulWidget {
  const NeracaJurnalScreen({super.key});

  @override
  State<NeracaJurnalScreen> createState() => _NeracaJurnalScreenState();
}

class _NeracaJurnalScreenState extends State<NeracaJurnalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  DateTimeRange? _dateRange;
  String searchQuery = '';
  final AccountingRepository repository = AccountingRepository();
  List<JurnalUmum> _jurnalList = [];
  Map<String, dynamic> _neracaData = {
    'data': [],
    'total_debit': 0.0,
    'total_kredit': 0.0,
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Jurnal Umum
      final jurnal = await repository.getJurnalUmum(
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );
      setState(() => _jurnalList = jurnal);

      // Neraca Saldo
      final neraca = await repository.getNeracaSaldo(
        untilDate:
            _dateRange?.end ??
            DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
      );
      setState(() => _neracaData = neraca);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neraca,Jurnal Umum & Laba Rugi'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Neraca Saldo'),
            Tab(text: 'Jurnal Umum'),
            Tab(text: 'Laba Rugi'), // Tab baru
          ],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter & Search
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
                                DateFormat('MMMM yyyy').format(_selectedMonth),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.indigo),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedMonth,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedMonth = picked;
                                    _dateRange = null;
                                  });
                                  _loadData();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.date_range, size: 18),
                            label: const Text('Rentang'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.indigo),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (range != null) {
                                setState(() => _dateRange = range);
                                _loadData();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // TextField(
                      //   decoration: InputDecoration(
                      //     hintText: 'Cari keterangan / kode akun...',
                      //     prefixIcon: const Icon(Icons.search),
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //     filled: true,
                      //     fillColor: Colors.white,
                      //   ),
                      //   onChanged: (value) {
                      //     setState(() => searchQuery = value);
                      //     _loadData();
                      //   },
                      // ),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNeracaTab(),
                      _buildJurnalTab(),
                      _buildLabaRugiTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNeracaTab() {
    double totalDebit = _neracaData['total_debit'] ?? 0.0;
    double totalKredit = _neracaData['total_kredit'] ?? 0.0;
    final data = _neracaData['data'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard('Total Debit', totalDebit, Colors.blue.shade700),
            const SizedBox(height: 12),
            _buildSummaryCard('Total Kredit', totalKredit, Colors.red.shade700),
            const SizedBox(height: 24),

            const Text(
              'Detail Neraca Saldo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: data.map((akun) {
                  final balance = (akun['saldo'] as num).toDouble();
                  final color = balance > 0 ? Colors.blue : Colors.red;

                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withAlpha(2),
                          child: Icon(Icons.account_balance, color: color),
                        ),
                        title: Text(
                          '${akun['kode_akun']} - ${akun['nama_akun']}',
                        ),
                        trailing: Text(
                          formatCurrencyWithSymbol(balance.abs()),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJurnalTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _jurnalList.length,
        itemBuilder: (context, index) {
          final j = _jurnalList[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade100,
                child: const Icon(Icons.receipt_long, color: Colors.indigo),
              ),
              title: Text(
                j.keterangan,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tanggal: ${j.tanggal}'),
                  Text('Ref: ${j.noReferensi ?? "-"}'),
                  Text('Oleh: ${j.dibuatOleh ?? "-"}'),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kode Akun: ${j.kodeAkun} - ${j.namaAkun ?? "-"}'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Debit: ${formatCurrencyWithSymbol(j.debit)}',
                            style: const TextStyle(color: Colors.blue),
                          ),
                          Text(
                            'Kredit: ${formatCurrencyWithSymbol(j.kredit)}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabaRugiTab() {
    // 1. Kelompokkan data dari _jurnalList
    Map<String, double> pendapatanMap = {};
    Map<String, double> bebanMap = {};
    double totalPendapatan = 0;
    double totalBeban = 0;

    for (var j in _jurnalList) {
      // Logika: Kode akun '4' biasanya Pendapatan, '5' & '6' adalah Beban
      if (j.kodeAkun.startsWith('4')) {
        double saldo = (j.kredit - j.debit); // Pendapatan bertambah di Kredit
        pendapatanMap.update(
          j.namaAkun ?? j.kodeAkun,
          (v) => v + saldo,
          ifAbsent: () => saldo,
        );
        totalPendapatan += saldo;
      } else if (j.kodeAkun.startsWith('5') || j.kodeAkun.startsWith('6')) {
        double saldo = (j.debit - j.kredit); // Beban bertambah di Debit
        bebanMap.update(
          j.namaAkun ?? j.kodeAkun,
          (v) => v + saldo,
          ifAbsent: () => saldo,
        );
        totalBeban += saldo;
      }
    }

    double labaRugiBersih = totalPendapatan - totalBeban;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Ringkasan Laba Rugi Bersih
            _buildSummaryCard(
              labaRugiBersih >= 0 ? 'Laba Bersih' : 'Rugi Bersih',
              labaRugiBersih,
              labaRugiBersih >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            ),
            const SizedBox(height: 20),

            // SEKSI PENDAPATAN
            const Text(
              'PENDAPATAN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const Divider(thickness: 2),
            ...pendapatanMap.entries.map(
              (e) => _buildLabaRugiRow(e.key, e.value),
            ),
            _buildTotalRow('Total Pendapatan', totalPendapatan),

            const SizedBox(height: 30),

            // SEKSI BEBAN
            const Text(
              'BEBAN',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const Divider(thickness: 2),
            ...bebanMap.entries.map((e) => _buildLabaRugiRow(e.key, e.value)),
            _buildTotalRow('Total Beban', totalBeban),

            const SizedBox(height: 20),
            const Divider(thickness: 3),
            _buildTotalRow('LABA (RUGI) BERSIH', labaRugiBersih, isBold: true),
          ],
        ),
      ),
    );
  }

  // Helper Widget untuk Baris Item
  Widget _buildLabaRugiRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(formatCurrencyWithSymbol(amount))],
      ),
    );
  }

  // Helper Widget untuk Baris Total
  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          Text(
            formatCurrencyWithSymbol(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: amount < 0 && isBold ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withAlpha(15), color.withAlpha(5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: color.withAlpha(2),
            child: Icon(Icons.account_balance_wallet, color: color, size: 28),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            formatCurrencyWithSymbol(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  String formatCurrencyWithSymbol(double value) {
    return 'Rp ${nf.format(value)}';
  }
}
