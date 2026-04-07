import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_models.dart';

abstract class AppointmentRemoteDatasource {
  Future<List<DepartmentModel>> getDepartments();
  Future<List<DoctorModel>> getDoctorsByDepartment(String departmentId);
  Future<List<ScheduleModel>> getDoctorSchedules(String doctorId, DateTime date);
  Future<List<ShiftModel>> getShifts();
  Future<HospitalAppointmentModel> createAppointment(HospitalAppointmentModel appointment);
  Future<List<HospitalAppointmentModel>> getPatientAppointments(String patientId);
  Future<int> getNextQueueNumber(String doctorId, DateTime date, String shiftId);
  Future<List<int>> getTakenQueueNumbers(String doctorId, DateTime date, String shiftId);
  Future<List<HospitalAppointmentModel>> getPatientActiveAppointments(String patientId);
}

class AppointmentRemoteDatasourceImpl implements AppointmentRemoteDatasource {
  final FirebaseFirestore firestore;

  AppointmentRemoteDatasourceImpl({required this.firestore});

  @override
  Future<List<DepartmentModel>> getDepartments() async {
    final snapshot = await firestore.collection('Departments').get();
    return snapshot.docs.map((doc) => DepartmentModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<DoctorModel>> getDoctorsByDepartment(String departmentId) async {
    final snapshot = await firestore
        .collection('Doctors')
        .where('departmentId', isEqualTo: departmentId)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => DoctorModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<ScheduleModel>> getDoctorSchedules(String doctorId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Fix: To avoid composite index error, we only query docId and filter date locally
    final snapshot = await firestore
        .collection('DoctorSchedules')
        .where('doctorId', isEqualTo: doctorId)
        .get();
        
    return snapshot.docs
        .map((doc) => ScheduleModel.fromFirestore(doc))
        .where((s) => 
            s.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && 
            s.date.isBefore(endOfDay))
        .toList();
  }

  @override
  Future<List<ShiftModel>> getShifts() async {
    // Normalizing shifts as they are usually static or managed in a collection
    final snapshot = await firestore.collection('Shifts').get();
    if (snapshot.docs.isEmpty) {
      // Fallback or Initial seed logic could go here
      return [];
    }
    return snapshot.docs.map((doc) => ShiftModel.fromFirestore(doc)).toList();
  }

  @override
  Future<HospitalAppointmentModel> createAppointment(HospitalAppointmentModel appointment) async {
    final docRef = await firestore.collection('Appointments').add(appointment.toFirestore());
    final snapshot = await docRef.get();
    return HospitalAppointmentModel.fromFirestore(snapshot);
  }

  @override
  Future<List<HospitalAppointmentModel>> getPatientAppointments(String patientId) async {
    final snapshot = await firestore
        .collection('Appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('appointmentDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => HospitalAppointmentModel.fromFirestore(doc)).toList();
  }

  @override
  Future<int> getNextQueueNumber(String doctorId, DateTime date, String shiftId) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // To avoid index error, filter date locally
    final snapshot = await firestore
        .collection('Appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('shiftId', isEqualTo: shiftId)
        .get();
    
    final count = snapshot.docs.where((doc) {
      final appDate = (doc.data()['appointmentDate'] as Timestamp).toDate();
      return appDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && 
             appDate.isBefore(endOfDay);
    }).length;

    return count + 1;
  }

  @override
  Future<List<int>> getTakenQueueNumbers(String doctorId, DateTime date, String shiftId) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // To avoid index error, filter date locally
    final snapshot = await firestore
        .collection('Appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('shiftId', isEqualTo: shiftId)
        .get();
    
    return snapshot.docs.where((doc) {
      final appDate = (doc.data()['appointmentDate'] as Timestamp).toDate();
      return appDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && 
             appDate.isBefore(endOfDay);
    }).map((doc) => doc.data()['queueNumber'] as int).toList();
  }

  @override
  Future<List<HospitalAppointmentModel>> getPatientActiveAppointments(String patientId) async {
    final snapshot = await firestore
        .collection('Appointments')
        .where('patientId', isEqualTo: patientId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();
    
    return snapshot.docs
        .map((doc) => HospitalAppointmentModel.fromFirestore(doc))
        .toList();
  }
}
