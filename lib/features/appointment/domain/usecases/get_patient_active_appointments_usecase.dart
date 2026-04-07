import '../entities/appointment_entities.dart';
import '../repositories/appointment_repository.dart';

class GetPatientActiveAppointmentsUsecase {
  final AppointmentRepository repository;

  GetPatientActiveAppointmentsUsecase({required this.repository});

  Future<List<HospitalAppointment>> call(String patientId) async {
    return await repository.getPatientActiveAppointments(patientId);
  }
}
