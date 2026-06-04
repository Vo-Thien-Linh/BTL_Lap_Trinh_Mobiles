import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_models.dart';
import '../../../../services/firestore_sequence_service.dart';

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
  Future<bool> hasScheduleConflict({
    required String patientId,
    required DateTime date,
    required String shiftId,
    String? timeSlot,
  });
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
    final lockRef = firestore
        .collection('PatientScheduleLocks')
        .doc(
          _patientScheduleLockId(
            appointment.patientId,
            appointment.appointmentDate,
            appointment.shiftId,
          ),
        );

    final hasExistingConflict = await hasScheduleConflict(
      patientId: appointment.patientId,
      date: appointment.appointmentDate,
      shiftId: appointment.shiftId,
      timeSlot: appointment.timeSlot,
    );
    if (hasExistingConflict) {
      throw Exception(
        'Bạn đã có lịch khám trong ca này. Vui lòng chọn ngày, buổi hoặc bác sĩ khác.',
      );
    }

    await firestore.runTransaction((transaction) async {
      final scheduleSnapshot = await transaction.get(scheduleRef);
      if (!scheduleSnapshot.exists) {
        throw Exception('Ca làm việc của bác sĩ không tồn tại.');
      }

      final scheduleData = scheduleSnapshot.data() ?? {};
      final isActive = (scheduleData['isActive'] ?? false) as bool;
      final availableSlots =
          int.tryParse(
            (scheduleData['remainingSlots'] ??
                    scheduleData['availableSlots'] ??
                    '0')
                .toString(),
          ) ??
          0;
      final maxSlots =
          int.tryParse(
            (scheduleData['slotCapacity'] ?? scheduleData['maxSlots'] ?? '10')
                .toString(),
          ) ??
          10;
      final bookedSlots =
          int.tryParse(scheduleData['bookedSlots']?.toString() ?? '0') ?? 0;

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
      final lockSnapshot = await transaction.get(lockRef);
      if (lockSnapshot.exists &&
          _isHoldingScheduleLock(lockSnapshot.data() ?? const {})) {
        var lockStillHoldsAppointment = true;
        final lockedAppointmentId =
            (lockSnapshot.data() ?? const {})['appointmentId']
                ?.toString()
                .trim();
        if (lockedAppointmentId != null && lockedAppointmentId.isNotEmpty) {
          final lockedAppointmentSnapshot = await transaction.get(
            firestore.collection('Appointments').doc(lockedAppointmentId),
          );
          final lockedAppointmentData =
              lockedAppointmentSnapshot.data() ?? const {};
          final lockedAppointmentDate = _toDate(
            lockedAppointmentData['appointmentDate'],
          );
          lockStillHoldsAppointment =
              lockedAppointmentSnapshot.exists &&
              lockedAppointmentDate != null &&
              _isHoldingAppointmentStatus(
                lockedAppointmentData['status']?.toString(),
                lockedAppointmentDate,
                lockedAppointmentData,
              );
        }
        if (!lockStillHoldsAppointment) {
          transaction.set(lockRef, {
            'status': 'released',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        if (lockStillHoldsAppointment) {
          throw Exception(
            'Bạn đã có lịch khám trong ca này. Vui lòng chọn ngày, buổi hoặc bác sĩ khác.',
          );
        }
      }

      final appointmentCode = appointment.appointmentCode.trim().isNotEmpty
          ? appointment.appointmentCode.trim()
          : await FirestoreSequenceService.generateNextCodeInTransaction(
              transaction: transaction,
              firestore: firestore,
              entityType: 'appointments',
            );

      transaction.update(scheduleRef, {
        'availableSlots': availableSlots - 1,
        'remainingSlots': availableSlots - 1,
        'bookedSlots': bookedSlots + 1,
        'slotCapacity': maxSlots,
        'maxSlots': maxSlots,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(appointmentRef, {
        ...appointment.toFirestore(),
        'id': appointmentId,
        'appointmentCode': appointmentCode,
        'queueOrder': appointment.queueNumber,
        'paymentStatus': appointment.paymentStatus.isEmpty
            ? 'unpaid'
            : appointment.paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(lockRef, {
        'patientId': appointment.patientId,
        'appointmentId': appointmentId,
        'appointmentDate': Timestamp.fromDate(appointment.appointmentDate),
        'shiftId': appointment.shiftId,
        'timeSlot': appointment.timeSlot,
        'scheduleId': scheduleId,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
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
  Future<bool> hasScheduleConflict({
    required String patientId,
    required DateTime date,
    required String shiftId,
    String? timeSlot,
  }) async {
    if (patientId.trim().isEmpty || shiftId.trim().isEmpty) return false;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await firestore
        .collection('Appointments')
        .where('patientId', isEqualTo: patientId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final appDate = _toDate(data['appointmentDate']);
      if (appDate == null ||
          appDate.isBefore(startOfDay) ||
          !appDate.isBefore(endOfDay)) {
        continue;
      }

      final status = data['status']?.toString();
      if (!_isHoldingAppointmentStatus(status, appDate, data)) continue;

      final appShiftId = data['shiftId']?.toString().trim() ?? '';
      final appTimeSlot = data['timeSlot']?.toString().trim() ?? '';
      final appAppointmentTime =
          data['appointmentTime']?.toString().trim() ?? '';
      final requestedTimeSlot = timeSlot?.trim() ?? '';

      if (appShiftId == shiftId.trim() ||
          (requestedTimeSlot.isNotEmpty &&
              (appTimeSlot == requestedTimeSlot ||
                  appAppointmentTime == requestedTimeSlot))) {
        return true;
      }
    }

    return false;
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
      final data = doc.data();
      if (_isReleasedAppointmentStatus(data['status']?.toString())) continue;

      final appDate = (data['appointmentDate'] as Timestamp).toDate();
      final isSameDay =
          appDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          appDate.isBefore(endOfDay);
      if (!isSameDay) continue;

      final queueNumber =
          int.tryParse(data['queueNumber']?.toString() ?? '0') ?? 0;
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
          final data = doc.data();
          if (_isReleasedAppointmentStatus(data['status']?.toString())) {
            return false;
          }

          final appDate = (data['appointmentDate'] as Timestamp).toDate();
          return appDate.isAfter(
                startOfDay.subtract(const Duration(seconds: 1)),
              ) &&
              appDate.isBefore(endOfDay);
        })
        .map((doc) => int.tryParse(doc.data()['queueNumber'].toString()) ?? 0)
        .where((number) => number > 0)
        .toList();
  }

  bool _isReleasedAppointmentStatus(String? status) {
    final normalized = status?.trim().toLowerCase();
    return normalized == 'cancelled' ||
        normalized == 'canceled' ||
        normalized == 'rejected';
  }

  bool _isHoldingAppointmentStatus(
    String? status,
    DateTime appointmentDate,
    Map<String, dynamic> data,
  ) {
    final normalized = status?.trim().toLowerCase() ?? '';
    if (normalized == 'scheduled' ||
        normalized == 'confirmed' ||
        normalized == 'pending' ||
        normalized == 'cancel_requested' ||
        normalized.startsWith('waiting')) {
      return true;
    }
    if (normalized == 'completed') {
      return !_isAppointmentTimePast(appointmentDate, data);
    }
    return false;
  }

  bool _isHoldingScheduleLock(Map<String, dynamic> data) {
    final status = data['status']?.toString().trim().toLowerCase() ?? 'active';
    return status == 'active' ||
        status == 'scheduled' ||
        status == 'confirmed' ||
        status == 'pending' ||
        status == 'cancel_requested' ||
        status.startsWith('waiting');
  }

  bool _isAppointmentTimePast(
    DateTime appointmentDate,
    Map<String, dynamic> data,
  ) {
    final timeText =
        (data['endTime'] ?? data['timeSlot'] ?? data['appointmentTime'])
            ?.toString()
            .trim() ??
        '';
    final dateTime = _timeOnDate(appointmentDate, timeText);
    if (dateTime != null) return dateTime.isBefore(DateTime.now());

    final day = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return day.isBefore(today);
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  DateTime? _timeOnDate(DateTime date, String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _patientScheduleLockId(
    String patientId,
    DateTime date,
    String shiftId,
  ) {
    final dateKey =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final raw = '${patientId}_${dateKey}_$shiftId';
    return raw.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
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
