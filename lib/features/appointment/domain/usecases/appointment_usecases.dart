import '../entities/appointment_entities.dart';
import '../repositories/appointment_repository.dart';

class GetDepartmentsUsecase {
  final AppointmentRepository repository;
  GetDepartmentsUsecase(this.repository);

  Future<List<DepartmentEntity>> call() async => await repository.getDepartments();
}

class GetDoctorsByDeptUsecase {
  final AppointmentRepository repository;
  GetDoctorsByDeptUsecase(this.repository);

  Future<List<DoctorEntity>> call(String departmentId) async =>
      await repository.getDoctorsByDepartment(departmentId);
}

class GetDoctorSchedulesUsecase {
  final AppointmentRepository repository;
  GetDoctorSchedulesUsecase(this.repository);

  Future<List<ScheduleEntity>> call(String doctorId, DateTime date) async =>
      await repository.getDoctorSchedules(doctorId, date);
}

class CreateAppointmentUsecase {
  final AppointmentRepository repository;
  CreateAppointmentUsecase(this.repository);

  Future<HospitalAppointment> call(HospitalAppointment appointment) async =>
      await repository.createAppointment(appointment);
}

class GetNextQueueNumberUsecase {
  final AppointmentRepository repository;
  GetNextQueueNumberUsecase(this.repository);

  Future<int> call(String doctorId, DateTime date, String shiftId) async =>
      await repository.getNextQueueNumber(doctorId, date, shiftId);
}

class GetTakenQueueNumbersUsecase {
  final AppointmentRepository repository;
  GetTakenQueueNumbersUsecase(this.repository);

  Future<List<int>> call(String doctorId, DateTime date, String shiftId) async =>
      await repository.getTakenQueueNumbers(doctorId, date, shiftId);
}

class GetPatientActiveAppointmentsUsecase {
  final AppointmentRepository repository;
  GetPatientActiveAppointmentsUsecase(this.repository);

  Future<List<HospitalAppointment>> call(String patientId) async =>
      await repository.getPatientActiveAppointments(patientId);
}
