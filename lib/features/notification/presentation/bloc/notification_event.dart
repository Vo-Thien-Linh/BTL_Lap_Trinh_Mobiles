part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class RegisterNotificationDeviceEvent extends NotificationEvent {
  final String? role;
  final String? email;
  const RegisterNotificationDeviceEvent({this.role, this.email});
  @override
  List<Object?> get props => [role, email];
}

class WatchNotificationsEvent extends NotificationEvent {
  final String userId;
  final NotificationRecipientRole? role;
  final int limit;
  const WatchNotificationsEvent({required this.userId, this.role, this.limit = 100});
  @override
  List<Object?> get props => [userId, role, limit];
}

class _NotificationsStreamUpdated extends NotificationEvent {
  final List<NotificationEntity> notifications;
  const _NotificationsStreamUpdated(this.notifications);
  @override
  List<Object?> get props => [notifications];
}

class GetNotificationsEvent extends NotificationEvent {
  final String userId;
  final NotificationRecipientRole? role;
  final int limit;
  const GetNotificationsEvent({required this.userId, this.role, this.limit = 100});
  @override
  List<Object?> get props => [userId, role, limit];
}

class SendAppointmentConfirmationEvent extends NotificationEvent {
  final String userId;
  final String appointmentId;
  final String doctorName;
  final DateTime appointmentTime;
  final String departmentName;
  final String? email;
  const SendAppointmentConfirmationEvent({
    required this.userId,
    required this.appointmentId,
    required this.doctorName,
    required this.appointmentTime,
    required this.departmentName,
    this.email,
  });
  @override
  List<Object?> get props => [userId, appointmentId, doctorName, appointmentTime, departmentName, email];
}

class SendAppointmentCancelledEvent extends NotificationEvent {
  final String userId;
  final String appointmentId;
  final String doctorName;
  final String? email;
  const SendAppointmentCancelledEvent({required this.userId, required this.appointmentId, required this.doctorName, this.email});
  @override
  List<Object?> get props => [userId, appointmentId, doctorName, email];
}

class ScheduleAppointmentRemindersEvent extends NotificationEvent {
  final String userId;
  final String appointmentId;
  final String doctorName;
  final DateTime appointmentTime;
  final String departmentId;
  final String departmentName;
  final String? patientEmail;
  const ScheduleAppointmentRemindersEvent({
    required this.userId,
    required this.appointmentId,
    required this.doctorName,
    required this.appointmentTime,
    required this.departmentId,
    required this.departmentName,
    this.patientEmail,
  });
  @override
  List<Object?> get props => [userId, appointmentId, doctorName, appointmentTime, departmentId, departmentName, patientEmail];
}

class SendPreparationInstructionsEvent extends NotificationEvent {
  final String userId;
  final String appointmentId;
  final String departmentId;
  final String departmentName;
  final DateTime appointmentTime;
  const SendPreparationInstructionsEvent({
    required this.userId,
    required this.appointmentId,
    required this.departmentId,
    required this.departmentName,
    required this.appointmentTime,
  });
  @override
  List<Object?> get props => [userId, appointmentId, departmentId, departmentName, appointmentTime];
}

class SendExaminationCompleteEvent extends NotificationEvent {
  final String userId;
  final String appointmentId;
  final String doctorName;
  const SendExaminationCompleteEvent({required this.userId, required this.appointmentId, required this.doctorName});
  @override
  List<Object?> get props => [userId, appointmentId, doctorName];
}

class SendResultAvailableEvent extends NotificationEvent {
  final String patientId;
  final String appointmentId;
  final String serviceName;
  const SendResultAvailableEvent({required this.patientId, required this.appointmentId, required this.serviceName});
  @override
  List<Object?> get props => [patientId, appointmentId, serviceName];
}

class SendDoctorNotificationEvent extends NotificationEvent {
  final String doctorId;
  final NotificationType type;
  final NotificationCategory category;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? deepLink;
  const SendDoctorNotificationEvent({
    required this.doctorId,
    required this.type,
    required this.title,
    required this.body,
    this.category = NotificationCategory.system,
    this.data = const {},
    this.deepLink,
  });
  @override
  List<Object?> get props => [doctorId, type, category, title, body, data, deepLink];
}

class ScheduleMedicationRemindersEvent extends NotificationEvent {
  final String userId;
  final String prescriptionId;
  final List<DateTime> reminderTimes;
  const ScheduleMedicationRemindersEvent({required this.userId, required this.prescriptionId, required this.reminderTimes});
  @override
  List<Object?> get props => [userId, prescriptionId, reminderTimes];
}

class MarkAsReadEvent extends NotificationEvent {
  final String notificationId;
  const MarkAsReadEvent({required this.notificationId});
  @override
  List<Object?> get props => [notificationId];
}

class MarkAllAsReadEvent extends NotificationEvent {
  final String userId;
  final NotificationRecipientRole? role;
  const MarkAllAsReadEvent({required this.userId, this.role});
  @override
  List<Object?> get props => [userId, role];
}

class DeleteNotificationEvent extends NotificationEvent {
  final String notificationId;
  const DeleteNotificationEvent({required this.notificationId});
  @override
  List<Object?> get props => [notificationId];
}

class LoadNotificationTemplatesEvent extends NotificationEvent {
  final String departmentId;
  const LoadNotificationTemplatesEvent({required this.departmentId});
  @override
  List<Object?> get props => [departmentId];
}
