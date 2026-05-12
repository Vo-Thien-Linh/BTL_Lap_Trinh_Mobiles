import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationFacade {
  NotificationFacade._();

  static NotificationRepository get _repo => GetIt.instance<NotificationRepository>();
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<void> registerCurrentDevice({String? role, String? email}) async {
    await _repo.registerCurrentDevice(role: role, email: email);
  }

  static Future<void> onAppointmentCreated({
    required String appointmentId,
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String departmentId,
    required String departmentName,
    required DateTime appointmentTime,
    String? patientEmail,
  }) async {
    final doctorUserId = await _resolveDoctorUserId(doctorId) ?? doctorId;
    final email = patientEmail ?? await _resolveEmail(patientId);

    await _repo.notify(NotificationEntity(
      id: 'appointment_created_${DateTime.now().microsecondsSinceEpoch}',
      userId: patientId,
      patientId: patientId,
      doctorId: doctorUserId,
      recipientRole: NotificationRecipientRole.patient,
      type: NotificationType.appointmentConfirmed,
      category: NotificationCategory.appointment,
      title: 'Đặt lịch khám thành công',
      body: 'Bạn đã đặt lịch với BS. $doctorName tại $departmentName vào ${_formatDateTime(appointmentTime)}.',
      data: {
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'doctorUserId': doctorUserId,
        'doctorName': doctorName,
        'departmentId': departmentId,
        'departmentName': departmentName,
        'appointmentTime': appointmentTime.toIso8601String(),
      },
      createdAt: DateTime.now(),
      deepLink: '/appointment-detail?id=$appointmentId',
      sendEmail: email != null,
      email: email,
    ));

    await _repo.notify(NotificationEntity(
      id: 'doctor_new_patient_${DateTime.now().microsecondsSinceEpoch}',
      userId: doctorUserId,
      patientId: patientId,
      doctorId: doctorUserId,
      recipientRole: NotificationRecipientRole.doctor,
      type: NotificationType.doctorNewPatient,
      category: NotificationCategory.appointment,
      title: 'Có bệnh nhân mới',
      body: '$patientName đã đặt lịch khám vào ${_formatDateTime(appointmentTime)} tại $departmentName.',
      data: {
        'appointmentId': appointmentId,
        'patientId': patientId,
        'patientName': patientName,
        'departmentId': departmentId,
        'departmentName': departmentName,
        'appointmentTime': appointmentTime.toIso8601String(),
      },
      createdAt: DateTime.now(),
      deepLink: '/doctor-queue',
    ));

    await _repo.scheduleAppointmentReminders(
      appointmentId: appointmentId,
      userId: patientId,
      appointmentTime: appointmentTime,
      doctorName: doctorName,
      departmentId: departmentId,
      departmentName: departmentName,
      patientEmail: email,
      deepLink: '/appointment-detail?id=$appointmentId',
    );
  }

  static Future<void> onAppointmentCancelled({
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required String doctorName,
    String? patientEmail,
  }) async {
    final doctorUserId = await _resolveDoctorUserId(doctorId) ?? doctorId;
    final email = patientEmail ?? await _resolveEmail(patientId);

    await _repo.cancelAppointmentNotifications(appointmentId);

    await _repo.notify(NotificationEntity(
      id: 'appointment_cancelled_${DateTime.now().microsecondsSinceEpoch}',
      userId: patientId,
      patientId: patientId,
      doctorId: doctorUserId,
      recipientRole: NotificationRecipientRole.patient,
      type: NotificationType.appointmentCancelled,
      category: NotificationCategory.appointment,
      title: 'Hủy lịch khám thành công',
      body: 'Lịch khám với BS. $doctorName đã được hủy thành công.',
      data: {'appointmentId': appointmentId, 'doctorId': doctorId, 'doctorName': doctorName},
      createdAt: DateTime.now(),
      deepLink: '/appointment-management',
      sendEmail: email != null,
      email: email,
    ));

    await _repo.notify(NotificationEntity(
      id: 'doctor_appointment_cancelled_${DateTime.now().microsecondsSinceEpoch}',
      userId: doctorUserId,
      patientId: patientId,
      doctorId: doctorUserId,
      recipientRole: NotificationRecipientRole.doctor,
      type: NotificationType.appointmentCancelled,
      category: NotificationCategory.appointment,
      title: 'Bệnh nhân đã hủy lịch',
      body: 'Một lịch khám với bạn đã được hủy.',
      data: {'appointmentId': appointmentId, 'patientId': patientId},
      createdAt: DateTime.now(),
      deepLink: '/doctor-schedule',
    ));
  }

  static Future<void> onServiceResultSubmitted({
    required String patientId,
    required String doctorId,
    required String patientName,
    required String serviceName,
    required String appointmentId,
  }) async {
    final doctorUserId = await _resolveDoctorUserId(doctorId) ?? doctorId;

    await _repo.notify(NotificationEntity(
      id: 'patient_service_result_${DateTime.now().microsecondsSinceEpoch}',
      userId: patientId,
      patientId: patientId,
      doctorId: doctorUserId,
      recipientRole: NotificationRecipientRole.patient,
      type: NotificationType.resultAvailable,
      category: NotificationCategory.medical,
      title: 'Đã có kết quả $serviceName',
      body: 'Kết quả $serviceName của bạn đã sẵn sàng. Vui lòng mở hồ sơ khám để xem chi tiết.',
      data: {'appointmentId': appointmentId, 'serviceName': serviceName},
      createdAt: DateTime.now(),
      deepLink: '/examination-detail?id=$appointmentId',
    ));

    await _repo.notify(NotificationEntity(
      id: 'doctor_service_completed_${DateTime.now().microsecondsSinceEpoch}',
      userId: doctorUserId,
      patientId: patientId,
      doctorId: doctorUserId,
      recipientRole: NotificationRecipientRole.doctor,
      type: NotificationType.serviceCompleted,
      category: NotificationCategory.service,
      title: 'Đã trả kết quả $serviceName',
      body: 'Quá trình $serviceName cho bệnh nhân $patientName đã hoàn tất.',
      data: {'appointmentId': appointmentId, 'patientId': patientId, 'patientName': patientName, 'serviceName': serviceName},
      createdAt: DateTime.now(),
      deepLink: '/doctor-service-queue',
    ));
  }

  static Future<void> onExaminationCompleted({
    required String patientId,
    required String doctorId,
    required String doctorName,
    required String appointmentId,
  }) async {
    final doctorUserId = await _resolveDoctorUserId(doctorId) ?? doctorId;

    await _repo.notify(NotificationEntity(
      id: 'patient_exam_completed_${DateTime.now().microsecondsSinceEpoch}',
      userId: patientId,
      patientId: patientId,
      doctorId: doctorUserId,
      recipientRole: NotificationRecipientRole.patient,
      type: NotificationType.examinationCompleted,
      category: NotificationCategory.medical,
      title: 'Hoàn tất thăm khám',
      body: 'Ca khám cùng BS. $doctorName đã hoàn tất. Vui lòng kiểm tra kết quả, hóa đơn hoặc đơn thuốc nếu có.',
      data: {'appointmentId': appointmentId, 'doctorId': doctorId, 'doctorName': doctorName},
      createdAt: DateTime.now(),
      deepLink: '/examination-detail?id=$appointmentId',
    ));

    await _repo.notify(NotificationEntity(
      id: 'doctor_exam_completed_${DateTime.now().microsecondsSinceEpoch}',
      userId: doctorUserId,
      patientId: patientId,
      doctorId: doctorUserId,
      recipientRole: NotificationRecipientRole.doctor,
      type: NotificationType.examinationCompleted,
      category: NotificationCategory.medical,
      title: 'Đã hoàn tất quá trình khám',
      body: 'Bạn đã hoàn tất quá trình khám cho một bệnh nhân.',
      data: {'appointmentId': appointmentId, 'patientId': patientId},
      createdAt: DateTime.now(),
      deepLink: '/doctor-examination-list',
    ));
  }

  static Future<void> notifyDoctorTomorrowSchedule({
    required String doctorId,
    required int appointmentCount,
    required DateTime date,
  }) async {
    final doctorUserId = await _resolveDoctorUserId(doctorId) ?? doctorId;
    if (appointmentCount <= 0) return;

    await _repo.notify(NotificationEntity(
      id: 'doctor_tomorrow_schedule_${doctorUserId}_${date.year}_${date.month}_${date.day}',
      userId: doctorUserId,
      doctorId: doctorUserId,
      recipientRole: NotificationRecipientRole.doctor,
      type: NotificationType.doctorTomorrowSchedule,
      category: NotificationCategory.appointment,
      title: 'Lịch khám ngày mai',
      body: 'Ngày mai bạn có $appointmentCount ca khám. Vui lòng kiểm tra lịch trực.',
      data: {'date': date.toIso8601String(), 'appointmentCount': appointmentCount},
      createdAt: DateTime.now(),
      deepLink: '/doctor-schedule',
    ));
  }

  static DateTime combineDateAndTimeSlot(DateTime date, String timeSlot) {
    final parts = timeSlot.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static Future<String?> _resolveDoctorUserId(String doctorId) async {
    try {
      final doc = await _db.collection('Doctors').doc(doctorId).get();
      final data = doc.data();
      return data?['userId']?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _resolveEmail(String userId) async {
    try {
      final lower = await _db.collection('users').doc(userId).get();
      final lowerEmail = lower.data()?['email']?.toString();
      if (lowerEmail != null && lowerEmail.isNotEmpty) return lowerEmail;
      final upper = await _db.collection('Users').doc(userId).get();
      return upper.data()?['email']?.toString() ?? FirebaseAuth.instance.currentUser?.email;
    } catch (_) {
      return FirebaseAuth.instance.currentUser?.email;
    }
  }

  static String _formatDateTime(DateTime value) {
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} lúc ${value.hour}:$minute';
  }
}
