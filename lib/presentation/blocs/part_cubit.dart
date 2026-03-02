import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/part.dart';
import '../../data/repositories/part_repository.dart';

part 'part_state.dart';

class PartCubit extends Cubit<PartState> {
  final PartRepository _repository = PartRepository();

  PartCubit() : super(PartInitial());

  Future<void> loadAll() async {
    emit(PartLoading());
    try {
      final parts = await _repository.getAll();
      emit(PartLoaded(parts));
    } catch (e) {
      emit(PartError(e.toString()));
    }
  }

  Future<void> addPart(Part part) async {
    try {
      if (part.id == null) {
        await _repository.insert(part);
      } else {
        await _repository.update(part);
      }
      await loadAll();
    } catch (e) {
      emit(PartError(e.toString()));
    }
  }

  Future<void> updateStok(int partId, int qty) async {
    try {
      await _repository.updateStok(partId, qty);
      await loadAll();
    } catch (e) {
      emit(PartError(e.toString()));
    }
  }
}
