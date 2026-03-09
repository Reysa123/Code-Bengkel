part of 'part_cubit.dart';

abstract class PartState extends Equatable {
  const PartState();
  @override
  List<Object> get props => [];
}

class PartInitial extends PartState {}
class PartLoading extends PartState {}
class PartLoaded extends PartState {
  final List<Part> parts;
  const PartLoaded(this.parts);
  @override
  List<Object> get props => [parts];
}
class PartError extends PartState {
  final String message;
  const PartError(this.message);
  @override
  List<Object> get props => [message];
}