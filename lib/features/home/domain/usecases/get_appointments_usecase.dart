import '../entities/appointment_entity.dart';
import '../repositories/home_repository.dart';

class GetAppointmentsUsecase {
  final HomeRepository repository;

  GetAppointmentsUsecase({required this.repository});

  Future<List<AppointmentEntity>> call() async {
    return await repository.getAppointments();
  }
}
