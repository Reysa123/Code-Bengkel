part of 'external_order_cubit.dart';

enum ExternalOrderStatus { initial, loading, loaded, error }

class ExternalOrderState extends Equatable {
  final ExternalOrderStatus status;
  final List<ExternalOrder> orders;
  final String? message;

  const ExternalOrderState({
    this.status = ExternalOrderStatus.initial,
    this.orders = const [],
    this.message,
  });

  ExternalOrderState copyWith({
    ExternalOrderStatus? status,
    List<ExternalOrder>? orders,
    String? message,
  }) {
    return ExternalOrderState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, orders, message];
}