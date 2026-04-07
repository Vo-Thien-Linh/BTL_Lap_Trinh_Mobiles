import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../features/auth/domain/usecases/register_usecase.dart';
import '../features/home/data/datasources/home_local_datasource.dart';
import '../features/home/data/repositories/home_repository_impl.dart';
import '../features/home/domain/repositories/home_repository.dart';
import '../features/home/domain/usecases/get_appointments_usecase.dart';
import '../features/home/presentation/bloc/home_bloc.dart';
import '../features/onboarding/data/datasources/onboarding_local_datasource.dart';
import '../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../features/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import '../features/onboarding/domain/usecases/has_seen_onboarding_usecase.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
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

  if (!getIt.isRegistered<ForgotPasswordUsecase>()) {
    getIt.registerLazySingleton<ForgotPasswordUsecase>(
          () => ForgotPasswordUsecase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<LogoutUsecase>()) {
    getIt.registerLazySingleton<LogoutUsecase>(
      () => LogoutUsecase(repository: getIt<AuthRepository>()),
    );
  }

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
}
