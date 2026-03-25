import 'package:bengkel/data/models/external_order.dart';
import 'package:bengkel/data/repositories/external_order_repository.dart';
import 'package:bengkel/presentation/blocs/external_order_cubit.dart';
import 'package:bengkel/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class PenagihanVendorPage extends StatefulWidget {
  const PenagihanVendorPage({super.key});

  @override
  State<PenagihanVendorPage> createState() => _PenagihanVendorPageState();
}

class _PenagihanVendorPageState extends State<PenagihanVendorPage> {
  // Contoh Data SPK yang dikirim ke Vendor tapi belum dibayar
  String? selectedVendor;
  String nospk = "";
  List<String> vendors = [];
  List<ExternalOrder> filteredOrders = [];
  double totalHutangBerjalan = 0, totalTagihanDipilih = 0;
  @override
  void initState() {
    super.initState();
    context.read<ExternalOrderBloc>().add(LoadAllExternalOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Penagihan Vendor (Sublet)")),
      body: BlocBuilder<ExternalOrderBloc, ExternalOrderState>(
        builder: (context, state) {
          if (state.status == ExternalOrderStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ExternalOrderStatus.loaded) {
            print(state.orders.first.beli);
            //List<ExternalOrder> pendingSublets = state.orders;
            // 1. Ambil list vendor unik untuk Dropdown
            vendors = state.orders.map((e) => e.vendor!).toSet().toList();

            // 2. Filter order berdasarkan vendor yang dipilih
            filteredOrders = selectedVendor == null
                ? []
                : state.orders
                      .where((e) => e.vendor == selectedVendor)
                      .toList();

            // 3. Hitung Total Hutang Berjalan (Semua yang vendornya sama)
            totalHutangBerjalan = filteredOrders.fold(
              0,
              (sum, item) => sum + (item.beli ?? 0),
            );

            // 4. Hitung Total Tagihan (Hanya yang di-checklist/isSelect)
            totalTagihanDipilih = filteredOrders
                .where((e) => e.isSelect == true)
                .fold(0, (sum, item) => sum + (item.beli ?? 0));
            return Column(
              children: [
                // Bagian Header Vendor
                // DROPDOWN VENDOR
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Pilih Supplier / Vendor",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                    initialValue: selectedVendor,
                    items: vendors
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedVendor = val;
                      });
                    },
                  ),
                ),

                // INFO HUTANG BERJALAN
                if (selectedVendor != null)
                  ListTile(
                    tileColor: Colors.blue.withOpacity(0.1),
                    title: const Text(
                      "Total Hutang Berjalan di Vendor ini:",
                      style: TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      nf.format(totalHutangBerjalan),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Pilih SPK yang akan dibayar:"),
                ),

                // LIST PEKERJAAN
                Expanded(
                  child: filteredOrders.isEmpty
                      ? const Center(
                          child: Text("Silahkan pilih vendor terlebih dahulu"),
                        )
                      : ListView.builder(
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            var item = filteredOrders[index];
                            return CheckboxListTile(
                              title: Text(item.nospk!),
                              subtitle: Text(item.deskripsi!),
                              secondary: Text(nf.format(item.beli)),
                              value: item.isSelect ?? false,
                              onChanged: (val) {
                                setState(() {
                                  item.isSelect = val;
                                });
                              },
                            );
                          },
                        ),
                ),

                // SUMMARY & ACTION
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Tagihan Terpilih:"),
                          Text(
                            nf.format(totalTagihanDipilih),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: totalTagihanDipilih > 0
                                ? Colors.green
                                : Colors.grey,
                          ),
                          onPressed: totalTagihanDipilih > 0
                              ? () => _showKonfirmasiBayar(
                                  context,
                                  totalTagihanDipilih,
                                )
                              : null,
                          child: const Text(
                            "PROSES PELUNASAN",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('Tidak ada data order luar'));
        },
      ),
    );
  }

  void _showKonfirmasiBayar(BuildContext context, double totalTagihan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.green),
            const SizedBox(width: 10),
            const Text("Konfirmasi Pelunasan"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Anda akan melakukan pelunasan untuk vendor:"),
            Text(
              selectedVendor ?? "-",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            const Text("Total Pembayaran:"),
            Text(
              nf.format(totalTagihan),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.green,
              ),
            ),
            const Divider(),
            const Text(
              "Efek Akuntansi:\n"
              "• Debit: 202 (Hutang Sublet) (-)\n"
              "• Kredit: 101 (Kas) (-)",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BATAL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              // 1. Ambil ID dari item-item yang di-checklist
              final selectedIds = context
                  .read<ExternalOrderBloc>()
                  .state
                  .orders
                  .where(
                    (e) => e.vendor == selectedVendor && e.isSelect == true,
                  )
                  .map((e) => e.id!)
                  .toList();
              // 5. Ambil daftar No. SPK yang sedang dipilih dan gabungkan dengan koma
              String selectedNoSpk = context
                  .read<ExternalOrderBloc>()
                  .state
                  .orders
                  .where((e) => e.isSelect == true)
                  .map((e) => e.nospk!)
                  .join(", ");
              String tglHariIni = DateFormat(
                'yyyy-MM-dd',
              ).format(DateTime.now());
              // print(selectedIds);
              // 2. Panggil Method di Bloc untuk Proses Jurnal & Update Status
              ExternalOrderRepository().postJurnal(
                tglHariIni,
                selectedNoSpk,
                selectedVendor!,
                totalTagihan,
                90000,
                selectedIds,
              );

              Navigator.pop(context); // Tutup Dialog

              // 3. Tampilkan Feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Pelunasan ke $selectedVendor Berhasil Diposting",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              context.read<ExternalOrderBloc>().add(LoadAllExternalOrders());
            },
            child: const Text(
              "YA, LUNASKAN",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
