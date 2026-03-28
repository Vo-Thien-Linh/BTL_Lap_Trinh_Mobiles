import 'package:equatable/equatable.dart';
import '../../domain/entities/appointment_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<AppointmentEntity> appointments;
  final String userName;

  const HomeLoaded({required this.appointments, this.userName = 'Người dùng'});

  @override
  List<Object?> get props => [appointments, userName];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
