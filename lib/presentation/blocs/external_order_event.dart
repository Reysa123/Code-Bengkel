part of 'external_order_cubit.dart';

abstract class ExternalOrderEvent extends Equatable {
  const ExternalOrderEvent();

  @override
  List<Object?> get props => [];
}

class LoadExternalOrders extends ExternalOrderEvent {
  final int nowo;
  const LoadExternalOrders(this.nowo);
  @override
  List<Object?> get props => [nowo];
}
class LoadAllExternalOrders extends ExternalOrderEvent{}
class AddExternalOrder extends ExternalOrderEvent {
  final ExternalOrder order;
final int nowo;
  const AddExternalOrder(this.order,this.nowo);

  @override
  List<Object?> get props => [order,nowo];
}

class UpdateExternalOrder extends ExternalOrderEvent {
  final String order;
final int nowo;
  const UpdateExternalOrder(this.order,this.nowo);

  @override
  List<Object?> get props => [order,nowo];
}

class DeleteExternalOrder extends ExternalOrderEvent {
  final int id;
final int nowo;
  const DeleteExternalOrder(this.id,this.nowo);

  @override
  List<Object?> get props => [id,nowo];
}
