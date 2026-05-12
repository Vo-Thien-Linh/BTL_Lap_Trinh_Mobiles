import 'package:dartz/dartz.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

String _id(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

class RegisterNotificationDeviceUseCase {
  final NotificationRepository repository;
  RegisterNotificationDeviceUseCase(this.repository);

  Future<Either<Exception, void>> call({String? role, String? email}) {
    return repository.registerCurrentDevice(role: role, email: email);
  }
}

class SendAppointmentConfirmationUseCase {
  final NotificationRepository repository;
  SendAppointmentConfirmationUseCase(this.repository);

  Future<Either<Exception, void>> call({
    required String userId,
    required String appointmentId,
    required String doctorName,
    required DateTime appointmentTime,
    required String departmentName,
    String? email,
  }) {
    return repository.notify(NotificationEntity(
      id: _id('appointment_confirmed'),
      userId: userId,
      patientId: userId,
      recipientRole: NotificationRecipientRole.patient,
      type: NotificationType.appointmentConfirmed,
      category: NotificationCategory.appointment,
      title: 'Đặt lịch khám thành công',
      body: 'Lịch khám với BS. $doctorName tại $departmentName đã được ghi nhận. Thời gian: ${_formatDateTime(appointmentTime)}.',
      data: {
        'appointmentId': appointmentId,
        'doctorName': doctorName,
        'departmentName': departmentName,
        'appointmentTime': appointmentTime.toIso8601String(),
      },
      createdAt: DateTime.now(),
      deepLink: '/appointment-detail?id=$appointmentId',
      sendEmail: email != null,
      email: email,
    ));
  }
}

class SendAppointmentCancelledUseCase {
  final NotificationRepository repository;
  SendAppointmentCancelledUseCase(this.repository);

  Future<Either<Exception, void>> call({
    required String userId,
    required String appointmentId,
    required String doctorName,
    String? email,
  }) async {
    await repository.cancelAppointmentNotifications(appointmentId);
    return repository.notify(NotificationEntity(
      id: _id('appointment_cancelled'),
      userId: userId,
      patientId: userId,
      recipientRole: NotificationRecipientRole.patient,
      type: NotificationType.appointmentCancelled,
      category: NotificationCategory.appointment,
      title: 'Hủy lịch khám thành công',
      body: 'Lịch khám với BS. $doctorName đã được hủy thành công.',
      data: {'appointmentId': appointmentId, 'doctorName': doctorName},
      createdAt: DateTime.now(),
      deepLink: '/appointment-management',
      sendEmail: email != null,
      email: email,
    ));
  }
}

class ScheduleAppointmentRemindersUseCase {
  final NotificationRepository repository;
  ScheduleAppointmentRemindersUseCase(this.repository);

  Future<Either<Exception, void>> call({
    required String userId,
    required String appointmentId,
    required String doctorName,
    required DateTime appointmentTime,
    required String departmentId,
    required String departmentName,
    String? patientEmail,
  }) {
    return repository.scheduleAppointmentReminders(
      appointmentId: appointmentId,
      userId: userId,
      appointmentTime: appointmentTime,
      doctorName: doctorName,
      departmentId: departmentId,
      departmentName: departmentName,
      patientEmail: patientEmail,
      deepLink: '/appointment-detail?id=$appointmentId',
    );
  }
}

class SendPreparationInstructionsUseCase {
  final NotificationRepository repository;
  SendPreparationInstructionsUseCase(this.repository);

  Future<Either<Exception, void>> call({
    required String userId,
    required String appointmentId,
    required String departmentId,
    required String departmentName,
    required DateTime appointmentTime,
  }) async {
    final templateResult = await repository.getPreparationTemplate(departmentId);
    return templateResult.fold(
      (failure) => Left(failure),
      (template) {
        final body = template == null
            ? 'Vui lòng mang giấy tờ tùy thân, bảo hiểm y tế nếu có và đến sớm 15 phút.'
            : '${template.message}\n• ${template.instructions.join('\n• ')}';
        return repository.notify(NotificationEntity(
          id: _id('preparation'),
          userId: userId,
          patientId: userId,
          recipientRole: NotificationRecipientRole.patient,
          type: NotificationType.preparationInstruction,
          category: NotificationCategory.medical,
          title: template?.title ?? 'Hướng dẫn chuẩn bị trước khám',
          body: body,
          data: {
            'appointmentId': appointmentId,
            'departmentId': departmentId,
            'departmentName': departmentName,
            'appointmentTime': appointmentTime.toIso8601String(),
          },
          createdAt: DateTime.now(),
          deepLink: '/appointment-detail?id=$appointmentId',
        ));
      },
    );
  }
}

class SendExaminationCompleteUseCase {
  final NotificationRepository repository;
  SendExaminationCompleteUseCase(this.repository);

  Future<Either<Exception, void>> call({
    required String userId,
    required String appointmentId,
    required String doctorName,
  }) {
    return repository.notify(NotificationEntity(
      id: _id('exam_complete'),
      userId: userId,
      patientId: userId,
      recipientRole: NotificationRecipientRole.patient,
      type: NotificationType.examinationCompleted,
      category: NotificationCategory.medical,
      title: 'Hoàn tất thăm khám',
      body: 'Ca khám cùng BS. $doctorName đã hoàn tất. Bạn có thể xem kết quả, hóa đơn hoặc đơn thuốc nếu có.',
      data: {'appointmentId': appointmentId, 'doctorName': doctorName},
      createdAt: DateTime.now(),
      deepLink: '/examination-detail?id=$appointmentId',
    ));
  }
}

class SendResultAvailableUseCase {
  final NotificationRepository repository;
  SendResultAvailableUseCase(this.repository);

  Future<Either<Exception, void>> call({
    required String patientId,
    required String appointmentId,
    required String serviceName,
  }) {
    return repository.notify(NotificationEntity(
      id: _id('result_available'),
      userId: patientId,
      patientId: patientId,
      recipientRole: NotificationRecipientRole.patient,
      type: NotificationType.resultAvailable,
      category: NotificationCategory.medical,
      title: 'Đã có kết quả $serviceName',
      body: 'Kết quả $serviceName của bạn đã sẵn sàng. Vui lòng mở hồ sơ khám để xem chi tiết.',
      data: {'appointmentId': appointmentId, 'serviceName': serviceName},
      createdAt: DateTime.now(),
      deepLink: '/examination-detail?id=$appointmentId',
    ));
  }
}

class SendDoctorNotificationUseCase {
  final NotificationRepository repository;
  SendDoctorNotificationUseCase(this.repository);

  Future<Either<Exception, void>> call({
    required String doctorId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? deepLink,
    NotificationCategory category = NotificationCategory.system,
  }) {
    return repository.notify(NotificationEntity(
      id: _id('doctor_notice'),
      userId: doctorId,
      doctorId: doctorId,
      recipientRole: NotificationRecipientRole.doctor,
      type: type,
      category: category,
      title: title,
      body: body,
      data: data,
      createdAt: DateTime.now(),
      deepLink: deepLink,
    ));
  }
}

class ScheduleMedicationRemindersUseCase {
  final NotificationRepository repository;
  ScheduleMedicationRemindersUseCase(this.repository);

  Future<Either<Exception, void>> call({
    required String userId,
    required String prescriptionId,
    required List<DateTime> reminderTimes,
  }) {
    final now = DateTime.now();
    final notifications = reminderTimes.where((t) => t.isAfter(now)).map((time) {
      return NotificationEntity(
        id: 'medication_${prescriptionId}_${time.millisecondsSinceEpoch}',
        userId: userId,
        patientId: userId,
        recipientRole: NotificationRecipientRole.patient,
        type: NotificationType.medicationReminder,
        category: NotificationCategory.medical,
        title: 'Nhắc uống thuốc',
        body: 'Đã đến giờ uống thuốc theo đơn của bác sĩ.',
        data: {'prescriptionId': prescriptionId, 'time': time.toIso8601String()},
        createdAt: now,
        scheduledAt: time,
        deepLink: '/prescription-detail?id=$prescriptionId',
        deliveryStatus: 'scheduled',
      );
    }).toList();
    return repository.saveMany(notifications);
  }
}

class GetNotificationsUseCase {
  final NotificationRepository repository;
  GetNotificationsUseCase(this.repository);

  Future<Either<Exception, List<NotificationEntity>>> call(
    String userId, {
    NotificationRecipientRole? role,
    int limit = 100,
  }) {
    return repository.getNotifications(userId, role: role, limit: limit);
  }
}

class GetNotificationTemplatesByDepartmentUseCase {
  final NotificationRepository repository;
  GetNotificationTemplatesByDepartmentUseCase(this.repository);

  Future<Either<Exception, List<NotificationTemplateEntity>>> call(String departmentId) {
    return repository.getNotificationTemplatesByDepartment(departmentId);
  }
}

String _formatDateTime(DateTime value) {
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.day}/${value.month}/${value.year} lúc ${value.hour}:$minute';
}
