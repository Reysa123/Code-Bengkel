import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/mechanic.dart';
import '../../data/repositories/mechanic_repository.dart';

part 'mechanic_state.dart';

class MechanicCubit extends Cubit<MechanicState> {
  final MechanicRepository _repository = MechanicRepository();

  MechanicCubit() : super(MechanicInitial());

  Future<void> loadAll() async {
    emit(MechanicLoading());
    try {
      final mechanics = await _repository.getAll();
      emit(MechanicLoaded(mechanics));
    } catch (e) {
      emit(MechanicError(e.toString()));
    }
  }

  Future<void> addMechanic(Mechanic mechanic) async {
    try {
      await _repository.insert(mechanic);
      await loadAll();
    } catch (e) {
      emit(MechanicError(e.toString()));
    }
  }

  Future<void> deleteMechanic(int id) async {
    try {
      await _repository.delete(id);
      await loadAll();
    } catch (e) {
      emit(MechanicError(e.toString()));
    }
  }
}