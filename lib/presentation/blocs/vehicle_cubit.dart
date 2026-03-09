import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/vehicle.dart';
import '../../data/repositories/vehicle_repository.dart';

part 'vehicle_state.dart';

class VehicleCubit extends Cubit<VehicleState> {
  final VehicleRepository _repository = VehicleRepository();

  VehicleCubit() : super(VehicleInitial());

  Future<void> loadAll() async {
    emit(VehicleLoading());
    try {
      final vehicles = await _repository.getAll();
      emit(VehicleLoaded(vehicles));
    } catch (e) {
      emit(VehicleError(e.toString()));
    }
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    try {
      await _repository.insert(vehicle);
      await loadAll(); // refresh
    } catch (e) {
      emit(VehicleError(e.toString()));
    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      await _repository.update(vehicle);
      await loadAll();
    } catch (e) {
      emit(VehicleError(e.toString()));
    }
  }

  Future<void> deleteVehicle(int id) async {
    try {
      await _repository.delete(id);
      await loadAll();
    } catch (e) {
      emit(VehicleError(e.toString()));
    }
  }
}
