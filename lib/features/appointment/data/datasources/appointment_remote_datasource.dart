import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_models.dart';

abstract class AppointmentRemoteDatasource {
  Future<List<DepartmentModel>> getDepartments();
  Future<List<DoctorModel>> getDoctorsByDepartment(String departmentId);
  Future<List<ScheduleModel>> getDoctorSchedules(
    String doctorId,
    DateTime date,
  );
  Future<List<ShiftModel>> getShifts();
  Future<HospitalAppointmentModel> createAppointment(
    HospitalAppointmentModel appointment,
  );
  Future<List<HospitalAppointmentModel>> getPatientAppointments(
    String patientId,
  );
  Future<int> getNextQueueNumber(
    String doctorId,
    DateTime date,
    String shiftId,
  );
  Future<List<int>> getTakenQueueNumbers(
    String doctorId,
    DateTime date,
    String shiftId,
  );
  Future<List<HospitalAppointmentModel>> getPatientActiveAppointments(
    String patientId,
  );
}

class AppointmentRemoteDatasourceImpl implements AppointmentRemoteDatasource {
  final FirebaseFirestore firestore;

  AppointmentRemoteDatasourceImpl({required this.firestore});

  @override
  Future<List<DepartmentModel>> getDepartments() async {
    final snapshot = await firestore.collection('Departments').get();
    return snapshot.docs
        .map((doc) => DepartmentModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<DoctorModel>> getDoctorsByDepartment(String departmentId) async {
    final snapshot = await firestore
        .collection('Doctors')
        .where('departmentId', isEqualTo: departmentId)
        .where('isActive', isEqualTo: true)
        .get();

    return Future.wait(
      snapshot.docs.map((doc) async {
        final doctor = DoctorModel.fromFirestore(doc);
        final userData = await _getUserData(doctor.userId);
        return DoctorModel.withUserProfile(doctor, userData);
      }),
    );
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    if (userId.trim().isEmpty) return null;

    final lowerDoc = await firestore.collection('users').doc(userId).get();
    if (lowerDoc.exists) return lowerDoc.data();

    final uidSnapshot = await firestore
        .collection('users')
        .where('uid', isEqualTo: userId)
        .limit(1)
        .get();
    if (uidSnapshot.docs.isNotEmpty) return uidSnapshot.docs.first.data();

    return null;
  }

  @override
  Future<List<ScheduleModel>> getDoctorSchedules(
    String doctorId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Fix: To avoid composite index error, we only query docId and filter date locally
    final snapshot = await firestore
        .collection('DoctorSchedules')
        .where('doctorId', isEqualTo: doctorId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ScheduleModel.fromFirestore(doc))
        .where(
          (s) =>
              s.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              s.date.isBefore(endOfDay),
        )
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
  Future<HospitalAppointmentModel> createAppointment(
    HospitalAppointmentModel appointment,
  ) async {
    final scheduleId = appointment.scheduleId?.trim() ?? '';
    if (scheduleId.isEmpty) {
      throw Exception('Ca làm việc của bác sĩ không hợp lệ.');
    }

    final appointmentId = '${scheduleId}_${appointment.queueNumber}';
    final appointmentRef = firestore
        .collection('Appointments')
        .doc(appointmentId);
    final scheduleRef = firestore.collection('DoctorSchedules').doc(scheduleId);

    await firestore.runTransaction((transaction) async {
      final scheduleSnapshot = await transaction.get(scheduleRef);
      if (!scheduleSnapshot.exists) {
        throw Exception('Ca làm việc của bác sĩ không tồn tại.');
      }

      final scheduleData = scheduleSnapshot.data() ?? {};
      final isActive = (scheduleData['isActive'] ?? false) as bool;
      final availableSlots =
          int.tryParse(scheduleData['availableSlots']?.toString() ?? '0') ?? 0;
      final maxSlots =
          int.tryParse(scheduleData['maxSlots']?.toString() ?? '0') ?? 0;

      if (!isActive) {
        throw Exception('Ca làm việc này đã ngừng nhận lịch.');
      }
      if (availableSlots <= 0) {
        throw Exception('Ca làm việc này đã hết chỗ.');
      }
      if (maxSlots > 0 && appointment.queueNumber > maxSlots) {
        throw Exception('Số thứ tự vượt quá số lượt khám của ca.');
      }
      if ((scheduleData['doctorId'] ?? '').toString() != appointment.doctorId ||
          (scheduleData['departmentId'] ?? '').toString() !=
              appointment.departmentId ||
          (scheduleData['shiftId'] ?? '').toString() != appointment.shiftId) {
        throw Exception('Thông tin lịch hẹn không khớp với ca làm việc.');
      }

      final appointmentSnapshot = await transaction.get(appointmentRef);
      if (appointmentSnapshot.exists) {
        throw Exception(
          'Số thứ tự này vừa được người khác đặt. Vui lòng chọn số khác.',
        );
      }

      transaction.update(scheduleRef, {
        'availableSlots': availableSlots - 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(appointmentRef, {
        ...appointment.toFirestore(),
        'id': appointmentId,
        'queueOrder': appointment.queueNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final docRef = appointmentRef;
    final snapshot = await docRef.get();
    return HospitalAppointmentModel.fromFirestore(snapshot);
  }

  @override
  Future<List<HospitalAppointmentModel>> getPatientAppointments(
    String patientId,
  ) async {
    final snapshot = await firestore
        .collection('Appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('appointmentDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => HospitalAppointmentModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<int> getNextQueueNumber(
    String doctorId,
    DateTime date,
    String shiftId,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // To avoid index error, filter date locally
    final snapshot = await firestore
        .collection('Appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('shiftId', isEqualTo: shiftId)
        .get();

    var maxQueueNumber = 0;
    for (final doc in snapshot.docs) {
      final appDate = (doc.data()['appointmentDate'] as Timestamp).toDate();
      final isSameDay =
          appDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          appDate.isBefore(endOfDay);
      if (!isSameDay) continue;

      final queueNumber =
          int.tryParse(doc.data()['queueNumber']?.toString() ?? '0') ?? 0;
      if (queueNumber > maxQueueNumber) maxQueueNumber = queueNumber;
    }

    return maxQueueNumber + 1;
  }

  @override
  Future<List<int>> getTakenQueueNumbers(
    String doctorId,
    DateTime date,
    String shiftId,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // To avoid index error, filter date locally
    final snapshot = await firestore
        .collection('Appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('shiftId', isEqualTo: shiftId)
        .get();

    return snapshot.docs
        .where((doc) {
          final appDate = (doc.data()['appointmentDate'] as Timestamp).toDate();
          return appDate.isAfter(
                startOfDay.subtract(const Duration(seconds: 1)),
              ) &&
              appDate.isBefore(endOfDay);
        })
        .map((doc) => doc.data()['queueNumber'] as int)
        .toList();
  }

  @override
  Future<List<HospitalAppointmentModel>> getPatientActiveAppointments(
    String patientId,
  ) async {
    final snapshot = await firestore
        .collection('Appointments')
        .where('patientId', isEqualTo: patientId)
        .where('status', whereIn: ['pending', 'confirmed', 'cancel_requested'])
        .get();

    return snapshot.docs
        .map((doc) => HospitalAppointmentModel.fromFirestore(doc))
        .toList();
  }
}
