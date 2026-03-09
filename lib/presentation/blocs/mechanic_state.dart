part of 'mechanic_cubit.dart';

abstract class MechanicState extends Equatable {
  const MechanicState();
  @override
  List<Object> get props => [];
}

class MechanicInitial extends MechanicState {}
class MechanicLoading extends MechanicState {}
class MechanicLoaded extends MechanicState {
  final List<Mechanic> mechanics;
  const MechanicLoaded(this.mechanics);
  @override
  List<Object> get props => [mechanics];
}
class MechanicError extends MechanicState {
  final String message;
  const MechanicError(this.message);
  @override
  List<Object> get props => [message];
}