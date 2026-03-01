import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/work_order.dart';
import '../../data/models/wo_item.dart';
import '../../data/repositories/work_order_repository.dart';

part 'work_order_state.dart';

class WorkOrderCubit extends Cubit<WorkOrderState> {
  final WorkOrderRepository _repository = WorkOrderRepository();

  WorkOrderCubit() : super(WorkOrderInitial());

  Future<void> loadAll() async {
    emit(WorkOrderLoading());
    try {
      final workOrders = await _repository.getAll();
      emit(WorkOrderLoaded(workOrders));
    } catch (e) {
      emit(WorkOrderError(e.toString()));
    }
  }

  Future<void> createWorkOrder(WorkOrder wo, List<WoItem> items) async {
    emit(WorkOrderLoading());
    try {
      await _repository.insertWithItems(wo, items);
      emit(WorkOrderSuccess());
      await loadAll(); // refresh list
    } catch (e) {
      emit(WorkOrderError(e.toString()));
    }
  }
}