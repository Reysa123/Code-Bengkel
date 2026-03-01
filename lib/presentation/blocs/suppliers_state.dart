part of 'suppliers_cubit.dart';

abstract class SupplierState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SupplierLoaded extends SupplierState {
  final List<Supplier> suppliers;
  SupplierLoaded(this.suppliers);

  @override
  List<Object?> get props => [suppliers];
}

class SupplierError extends SupplierState {
  final String message;
  SupplierError(this.message);

  @override
  List<Object?> get props => [message];
}