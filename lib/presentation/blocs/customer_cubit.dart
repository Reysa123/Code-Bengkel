import 'package:bengkel/data/models/customer.dart';
import 'package:bengkel/data/repositories/customer_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'customer_state.dart'; // Sesuaikan path

class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRepository repository = CustomerRepository();

  CustomerCubit() : super(CustomerInitial());

  // Memuat semua data customer
  Future<void> loadAll() async {
    try {
      emit(CustomerLoading());
      final customers = await repository.getAllCustomers();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError("Gagal memuat data customer: ${e.toString()}"));
    }
  }

  // Menambah customer baru dan langsung mengembalikan objeknya
  // agar bisa langsung dipilih di form kendaraan
  Future<Customer?> addCustomer(Customer customer) async {
    try {
      final newId = await repository.insertCustomer(customer);
      final newCustomer = Customer(
        id: newId,
        nama: customer.nama,
        noHp: customer.noHp,
        alamat: customer.alamat,
      );

      // Refresh list agar pencarian terbaru muncul
      await loadAll();
      return newCustomer;
    } catch (e) {
      emit(CustomerError("Gagal menambah customer"));
      return null;
    }
  }

  // Fungsi pencarian lokal (Opsional, jika tidak ingin hit DB terus menerus)
  void searchCustomer(String query) async {
    if (state is CustomerLoaded) {
      final allCustomers = await repository.getAllCustomers();
      final filtered = allCustomers
          .where((c) => c.nama.toLowerCase().contains(query.toLowerCase()))
          .toList();
      emit(CustomerLoaded(filtered));
    }
  }
}
