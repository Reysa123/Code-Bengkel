import 'package:bengkel/data/models/external_order.dart';
import 'package:bengkel/data/repositories/external_order_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'external_order_event.dart';
part 'external_order_state.dart';

class ExternalOrderBloc extends Bloc<ExternalOrderEvent, ExternalOrderState> {
  final ExternalOrderRepository _repo = ExternalOrderRepository();

  ExternalOrderBloc() : super(const ExternalOrderState()) {
    on<LoadExternalOrders>(_onLoad);
    on<LoadAllExternalOrders>(_onLoadAll);
    on<AddExternalOrder>(_onAdd);
    on<UpdateExternalOrder>(_onUpdate);
    on<DeleteExternalOrder>(_onDelete);
  }

  Future<void> _onLoad(
    LoadExternalOrders event,
    Emitter<ExternalOrderState> emit,
  ) async {
    emit(state.copyWith(status: ExternalOrderStatus.loading));
    final list = await _repo.getByNoWo(event.nowo);
    emit(state.copyWith(status: ExternalOrderStatus.loaded, orders: list));
  }

  Future<void> _onLoadAll(
    LoadAllExternalOrders event,
    Emitter<ExternalOrderState> emit,
  ) async {
    emit(state.copyWith(status: ExternalOrderStatus.loading));
    final list = await _repo.getAll();
    emit(state.copyWith(status: ExternalOrderStatus.loaded, orders: list));
  }

  Future<int> _onAdd(
    AddExternalOrder event,
    Emitter<ExternalOrderState> emit,
  ) async {
    final a = await _repo.insert(event.order);
    add(LoadExternalOrders(event.nowo));
    return a;
  }

  Future<int> _onUpdate(
    UpdateExternalOrder event,
    Emitter<ExternalOrderState> emit,
  ) async {
    final a = await _repo.update(event.nowo, event.order);
    // add(LoadExternalOrders(event.nowo));
    return a;
  }

  Future<int> _onDelete(
    DeleteExternalOrder event,
    Emitter<ExternalOrderState> emit,
  ) async {
    final a = await _repo.delete(event.id);
    //add(LoadExternalOrders(event.nowo));
    return a;
  }
}
