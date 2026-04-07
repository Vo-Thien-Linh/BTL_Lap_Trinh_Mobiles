import '../entities/appointment_entities.dart';

abstract class AppointmentRepository {
  Future<List<DepartmentEntity>> getDepartments();
  Future<List<DoctorEntity>> getDoctorsByDepartment(String departmentId);
  Future<List<ScheduleEntity>> getDoctorSchedules(String doctorId, DateTime date);
  Future<List<ShiftEntity>> getShifts();
  Future<HospitalAppointment> createAppointment(HospitalAppointment appointment);
  Future<List<HospitalAppointment>> getPatientAppointments(String patientId);
  Future<int> getNextQueueNumber(String doctorId, DateTime date, String shiftId);
  Future<List<int>> getTakenQueueNumbers(String doctorId, DateTime date, String shiftId);
  Future<List<HospitalAppointment>> getPatientActiveAppointments(String patientId);
}
