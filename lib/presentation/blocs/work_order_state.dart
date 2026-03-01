part of 'work_order_cubit.dart';

abstract class WorkOrderState extends Equatable {
  const WorkOrderState();
  @override
  List<Object> get props => [];
}

class WorkOrderInitial extends WorkOrderState {}
class WorkOrderLoading extends WorkOrderState {}
class WorkOrderLoaded extends WorkOrderState {
  final List<WorkOrder> workOrders;
  const WorkOrderLoaded(this.workOrders);
  @override
  List<Object> get props => [workOrders];
}
class WorkOrderSuccess extends WorkOrderState {}
class WorkOrderError extends WorkOrderState {
  final String message;
  const WorkOrderError(this.message);
  @override
  List<Object> get props => [message];
}