import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/supplier.dart';
import '../../data/repositories/supplier_repository.dart';

part 'suppliers_state.dart';

class SupplierCubit extends Cubit<SupplierState> {
  final SupplierRepository _repository = SupplierRepository();

  SupplierCubit() : super(SupplierInitial());

  Future<void> loadAll() async {
    emit(SupplierLoading());
    try {
      final suppliers = await _repository.getAll();
      emit(SupplierLoaded(suppliers));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      await _repository.insert(supplier);
      await loadAll();
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      await _repository.update(supplier);
      await loadAll();
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _repository.delete(id);
      await loadAll();
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }
}
