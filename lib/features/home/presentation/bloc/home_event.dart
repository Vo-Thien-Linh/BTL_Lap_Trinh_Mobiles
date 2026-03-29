import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchAppointmentsEvent extends HomeEvent {
  const FetchAppointmentsEvent();
}

class RefreshAppointmentsEvent extends HomeEvent {
  const RefreshAppointmentsEvent();
}
