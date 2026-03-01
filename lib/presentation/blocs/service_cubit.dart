import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';

part 'service_state.dart';

class ServiceCubit extends Cubit<ServiceState> {
  final ServiceRepository _repository = ServiceRepository();

  ServiceCubit() : super(ServiceInitial());

  Future<void> loadAll() async {
    emit(ServiceLoading());
    try {
      final services = await _repository.getAll();
      emit(ServiceLoaded(services));
    } catch (e) {
      emit(ServiceError(e.toString()));
    }
  }

  Future<void> addService(Service service) async {
    try {
      await _repository.insert(service);
      await loadAll();
    } catch (e) {
      emit(ServiceError(e.toString()));
    }
  }
}