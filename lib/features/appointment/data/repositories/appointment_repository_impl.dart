import '../../domain/entities/appointment_entities.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_datasource.dart';
import '../models/appointment_models.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDatasource remoteDatasource;

  AppointmentRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<DepartmentEntity>> getDepartments() async {
    return await remoteDatasource.getDepartments();
  }

  @override
  Future<List<DoctorEntity>> getDoctorsByDepartment(String departmentId) async {
    return await remoteDatasource.getDoctorsByDepartment(departmentId);
  }

  @override
  Future<List<ScheduleEntity>> getDoctorSchedules(String doctorId, DateTime date) async {
    return await remoteDatasource.getDoctorSchedules(doctorId, date);
  }

  @override
  Future<List<ShiftEntity>> getShifts() async {
    return await remoteDatasource.getShifts();
  }

  @override
  Future<HospitalAppointment> createAppointment(HospitalAppointment appointment) async {
    final model = HospitalAppointmentModel(
      id: appointment.id,
      patientId: appointment.patientId,
      patientName: appointment.patientName,
      doctorId: appointment.doctorId,
      doctorName: appointment.doctorName,
      departmentId: appointment.departmentId,
      departmentName: appointment.departmentName,
      appointmentDate: appointment.appointmentDate,
      shiftId: appointment.shiftId,
      timeSlot: appointment.timeSlot,
      queueNumber: appointment.queueNumber,
      roomNumber: appointment.roomNumber,
      consultationFee: appointment.consultationFee,
      insuranceNumber: appointment.insuranceNumber,
      symptoms: appointment.symptoms,
      status: appointment.status,
      paymentMethod: appointment.paymentMethod,
      createdAt: appointment.createdAt,
    );
    return await remoteDatasource.createAppointment(model);
  }

  @override
  Future<List<HospitalAppointment>> getPatientAppointments(String patientId) async {
    return await remoteDatasource.getPatientAppointments(patientId);
  }

  @override
  Future<List<HospitalAppointment>> getPatientActiveAppointments(String patientId) async {
    return await remoteDatasource.getPatientActiveAppointments(patientId);
  }

  @override
  Future<int> getNextQueueNumber(String doctorId, DateTime date, String shiftId) async {
    return await remoteDatasource.getNextQueueNumber(doctorId, date, shiftId);
  }

  @override
  Future<List<int>> getTakenQueueNumbers(String doctorId, DateTime date, String shiftId) async {
    return await remoteDatasource.getTakenQueueNumbers(doctorId, date, shiftId);
  }
}
