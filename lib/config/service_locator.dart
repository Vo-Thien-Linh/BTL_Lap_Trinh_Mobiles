import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/register_usecase.dart';

import '../features/onboarding/data/datasources/onboarding_local_datasource.dart';
import '../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../features/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import '../features/onboarding/domain/usecases/has_seen_onboarding_usecase.dart';

import '../features/home/data/datasources/home_local_datasource.dart';
import '../features/home/data/repositories/home_repository_impl.dart';
import '../features/home/domain/repositories/home_repository.dart';
import '../features/home/domain/usecases/get_appointments_usecase.dart';
import '../features/home/presentation/bloc/home_bloc.dart';

import '../features/appointment/data/datasources/appointment_remote_datasource.dart';
import '../features/appointment/data/repositories/appointment_repository_impl.dart';
import '../features/appointment/domain/repositories/appointment_repository.dart';
import '../features/appointment/domain/usecases/appointment_usecases.dart';
import '../features/appointment/presentation/bloc/booking_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // --- External ---
  if (!getIt.isRegistered<FirebaseAuth>()) {
    getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }

  if (!getIt.isRegistered<FirebaseFirestore>()) {
    getIt.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }

  if (!getIt.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  }

  // --- Auth Feature ---
  if (!getIt.isRegistered<AuthRemoteDatasource>()) {
    getIt.registerLazySingleton<AuthRemoteDatasource>(
      () => AuthRemoteDatasourceImpl(
        firebaseAuth: getIt<FirebaseAuth>(),
        firestore: getIt<FirebaseFirestore>(),
      ),
    );
  }

  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDatasource: getIt<AuthRemoteDatasource>()),
    );
  }

  if (!getIt.isRegistered<LoginUsecase>()) {
    getIt.registerLazySingleton<LoginUsecase>(
      () => LoginUsecase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<RegisterUsecase>()) {
    getIt.registerLazySingleton<RegisterUsecase>(
      () => RegisterUsecase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<LogoutUsecase>()) {
    getIt.registerLazySingleton<LogoutUsecase>(
      () => LogoutUsecase(repository: getIt<AuthRepository>()),
    );
  }

  // --- Onboarding Feature ---
  if (!getIt.isRegistered<OnboardingLocalDatasource>()) {
    getIt.registerLazySingleton<OnboardingLocalDatasource>(
      () => OnboardingLocalDatasourceImpl(
        sharedPreferences: getIt<SharedPreferences>(),
      ),
    );
  }

  if (!getIt.isRegistered<OnboardingRepository>()) {
    getIt.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(
        localDatasource: getIt<OnboardingLocalDatasource>(),
      ),
    );
  }

  if (!getIt.isRegistered<HasSeenOnboardingUsecase>()) {
    getIt.registerLazySingleton<HasSeenOnboardingUsecase>(
      () => HasSeenOnboardingUsecase(repository: getIt<OnboardingRepository>()),
    );
  }

  if (!getIt.isRegistered<CompleteOnboardingUsecase>()) {
    getIt.registerLazySingleton<CompleteOnboardingUsecase>(
      () =>
          CompleteOnboardingUsecase(repository: getIt<OnboardingRepository>()),
    );
  }

  // --- Home Feature ---
  if (!getIt.isRegistered<HomeLocalDatasource>()) {
    getIt.registerLazySingleton<HomeLocalDatasource>(
      () => HomeLocalDatasourceImpl(),
    );
  }

  if (!getIt.isRegistered<HomeRepository>()) {
    getIt.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(localDatasource: getIt<HomeLocalDatasource>()),
    );
  }

  if (!getIt.isRegistered<GetAppointmentsUsecase>()) {
    getIt.registerLazySingleton<GetAppointmentsUsecase>(
      () => GetAppointmentsUsecase(repository: getIt<HomeRepository>()),
    );
  }

  if (!getIt.isRegistered<HomeBloc>()) {
    getIt.registerFactory<HomeBloc>(
      () => HomeBloc(getAppointmentsUsecase: getIt<GetAppointmentsUsecase>()),
    );
  }

  // --- Appointment Feature ---
  if (!getIt.isRegistered<AppointmentRemoteDatasource>()) {
    getIt.registerLazySingleton<AppointmentRemoteDatasource>(
      () => AppointmentRemoteDatasourceImpl(
        firestore: getIt<FirebaseFirestore>(),
      ),
    );
  }

  if (!getIt.isRegistered<AppointmentRepository>()) {
    getIt.registerLazySingleton<AppointmentRepository>(
      () => AppointmentRepositoryImpl(
        remoteDatasource: getIt<AppointmentRemoteDatasource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetDepartmentsUsecase>()) {
    getIt.registerLazySingleton<GetDepartmentsUsecase>(
      () => GetDepartmentsUsecase(getIt<AppointmentRepository>()),
    );
  }

  if (!getIt.isRegistered<GetDoctorsByDeptUsecase>()) {
    getIt.registerLazySingleton<GetDoctorsByDeptUsecase>(
      () => GetDoctorsByDeptUsecase(getIt<AppointmentRepository>()),
    );
  }

  if (!getIt.isRegistered<GetDoctorSchedulesUsecase>()) {
    getIt.registerLazySingleton<GetDoctorSchedulesUsecase>(
      () => GetDoctorSchedulesUsecase(getIt<AppointmentRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateAppointmentUsecase>()) {
    getIt.registerLazySingleton<CreateAppointmentUsecase>(
      () => CreateAppointmentUsecase(getIt<AppointmentRepository>()),
    );
  }

  if (!getIt.isRegistered<GetNextQueueNumberUsecase>()) {
    getIt.registerLazySingleton<GetNextQueueNumberUsecase>(
      () => GetNextQueueNumberUsecase(getIt<AppointmentRepository>()),
    );
  }

  if (!getIt.isRegistered<GetTakenQueueNumbersUsecase>()) {
    getIt.registerLazySingleton<GetTakenQueueNumbersUsecase>(
      () => GetTakenQueueNumbersUsecase(getIt<AppointmentRepository>()),
    );
  }

  if (!getIt.isRegistered<GetPatientActiveAppointmentsUsecase>()) {
    getIt.registerLazySingleton<GetPatientActiveAppointmentsUsecase>(
      () => GetPatientActiveAppointmentsUsecase(getIt<AppointmentRepository>()),
    );
  }

  if (!getIt.isRegistered<BookingBloc>()) {
    getIt.registerFactory<BookingBloc>(
      () => BookingBloc(
        getDepartments: getIt<GetDepartmentsUsecase>(),
        getDoctorsByDept: getIt<GetDoctorsByDeptUsecase>(),
        getDoctorSchedules: getIt<GetDoctorSchedulesUsecase>(),
        createAppointment: getIt<CreateAppointmentUsecase>(),
        getNextQueueNumber: getIt<GetNextQueueNumberUsecase>(),
        getTakenQueueNumbers: getIt<GetTakenQueueNumbersUsecase>(),
        getPatientActiveAppointments: getIt<GetPatientActiveAppointmentsUsecase>(),
      ),
    );
  }
}
