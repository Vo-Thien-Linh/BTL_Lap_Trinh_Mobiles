import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';
import '../models/appointment_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeLocalDatasource localDatasource;

  HomeRepositoryImpl({required this.localDatasource});

  @override
  Future<List<AppointmentEntity>> getAppointments() async {
    final models = await localDatasource.getAppointments();
    return models.map((model) => _mapModelToEntity(model)).toList();
  }

  AppointmentEntity _mapModelToEntity(AppointmentModel model) {
    return AppointmentEntity(
      id: model.id,
      doctorName: model.doctorName,
      specialization: model.specialization,
      appointmentDate: model.appointmentDate,
      time: model.time,
      status: model.status,
      doctorImage: model.doctorImage,
    );
  }
}
