import 'package:get_it/get_it.dart';
import '../features/home/data/datasources/home_local_datasource.dart';
import '../features/home/data/repositories/home_repository_impl.dart';
import '../features/home/domain/repositories/home_repository.dart';
import '../features/home/domain/usecases/get_appointments_usecase.dart';
import '../features/home/presentation/bloc/home_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
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
