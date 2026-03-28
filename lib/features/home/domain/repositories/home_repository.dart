import '../entities/appointment_entity.dart';

abstract class HomeRepository {
  Future<List<AppointmentEntity>> getAppointments();
}
