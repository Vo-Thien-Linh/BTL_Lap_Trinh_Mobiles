import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_appointments_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetAppointmentsUsecase getAppointmentsUsecase;

  HomeBloc({required this.getAppointmentsUsecase})
    : super(const HomeInitial()) {
    on<FetchAppointmentsEvent>(_onFetchAppointments);
    on<RefreshAppointmentsEvent>(_onRefreshAppointments);
  }

  Future<void> _onFetchAppointments(
    FetchAppointmentsEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    try {
      final appointments = await getAppointmentsUsecase();
      emit(HomeLoaded(appointments: appointments));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onRefreshAppointments(
    RefreshAppointmentsEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final appointments = await getAppointmentsUsecase();
      emit(HomeLoaded(appointments: appointments));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
