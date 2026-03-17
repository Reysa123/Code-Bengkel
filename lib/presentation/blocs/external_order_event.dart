part of 'external_order_cubit.dart';

abstract class ExternalOrderEvent extends Equatable {
  const ExternalOrderEvent();

  @override
  List<Object?> get props => [];
}

class LoadExternalOrders extends ExternalOrderEvent {}

class AddExternalOrder extends ExternalOrderEvent {
  final ExternalOrder order;

  const AddExternalOrder(this.order);

  @override
  List<Object?> get props => [order];
}

class UpdateExternalOrder extends ExternalOrderEvent {
  final ExternalOrder order;

  const UpdateExternalOrder(this.order);

  @override
  List<Object?> get props => [order];
}

class DeleteExternalOrder extends ExternalOrderEvent {
  final int id;

  const DeleteExternalOrder(this.id);

  @override
  List<Object?> get props => [id];
}