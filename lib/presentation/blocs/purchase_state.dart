part of 'purchase_cubit.dart';

abstract class PurchaseState extends Equatable {
  const PurchaseState();

  @override
  List<Object> get props => [];
}

class PurchaseInitial extends PurchaseState {}

class PurchaseLoading extends PurchaseState {}

class PurchaseSuccess extends PurchaseState {
  final int purchaseId;
  const PurchaseSuccess(this.purchaseId);

  @override
  List<Object> get props => [purchaseId];
}

class PurchaseLoaded extends PurchaseState {
  final List<Purchase> purchases;
  const PurchaseLoaded(this.purchases);

  @override
  List<Object> get props => [purchases];
}

class PurchaseError extends PurchaseState {
  final String message;
  const PurchaseError(this.message);

  @override
  List<Object> get props => [message];
}
