import 'package:equatable/equatable.dart';

enum NotificationType {
  appointmentCreated,
  appointmentConfirmed,
  appointmentCancelled,
  appointmentReminder24h,
  appointmentReminder1h,
  preparationInstruction,
  examinationCompleted,
  resultAvailable,
  serviceRequested,
  serviceStarted,
  serviceCompleted,
  doctorTomorrowSchedule,
  doctorNewPatient,
  medicationReminder,
  payment,
  system,
}

enum NotificationCategory { appointment, medical, service, payment, system }

enum NotificationRecipientRole { patient, doctor, admin }

class NotificationEntity extends Equatable {
  final String id;
  final String? notificationCode;
  final String userId;
  final String? patientId;
  final String? doctorId;
  final NotificationRecipientRole recipientRole;
  final NotificationType type;
  final NotificationCategory category;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final bool isRead;
  final String? deepLink;
  final bool sendPush;
  final bool sendEmail;
  final String? email;
  final String deliveryStatus; // pending, scheduled, delivered, failed
  final DateTime? deliveredAt;

  const NotificationEntity({
    required this.id,
    this.notificationCode,
    required this.userId,
    this.patientId,
    this.doctorId,
    required this.recipientRole,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    this.data = const {},
    required this.createdAt,
    this.scheduledAt,
    this.isRead = false,
    this.deepLink,
    this.sendPush = true,
    this.sendEmail = false,
    this.email,
    this.deliveryStatus = 'pending',
    this.deliveredAt,
  });

  bool get isScheduledForFuture =>
      scheduledAt != null && scheduledAt!.isAfter(DateTime.now());

  NotificationEntity copyWith({
    String? id,
    String? notificationCode,
    String? userId,
    String? patientId,
    String? doctorId,
    NotificationRecipientRole? recipientRole,
    NotificationType? type,
    NotificationCategory? category,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? scheduledAt,
    bool? isRead,
    String? deepLink,
    bool? sendPush,
    bool? sendEmail,
    String? email,
    String? deliveryStatus,
    DateTime? deliveredAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      notificationCode: notificationCode ?? this.notificationCode,
      userId: userId ?? this.userId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      recipientRole: recipientRole ?? this.recipientRole,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isRead: isRead ?? this.isRead,
      deepLink: deepLink ?? this.deepLink,
      sendPush: sendPush ?? this.sendPush,
      sendEmail: sendEmail ?? this.sendEmail,
      email: email ?? this.email,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    notificationCode,
    userId,
    patientId,
    doctorId,
    recipientRole,
    type,
    category,
    title,
    body,
    data,
    createdAt,
    scheduledAt,
    isRead,
    deepLink,
    sendPush,
    sendEmail,
    email,
    deliveryStatus,
    deliveredAt,
  ];
}

class NotificationTemplateEntity extends Equatable {
  final String id;
  final String departmentId;
  final String departmentName;
  final String templateType; // preparation, reminder, postExamination
  final String title;
  final String message;
  final List<String> instructions;
  final bool isActive;

  const NotificationTemplateEntity({
    required this.id,
    required this.departmentId,
    required this.departmentName,
    required this.templateType,
    required this.title,
    required this.message,
    required this.instructions,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
    id,
    departmentId,
    departmentName,
    templateType,
    title,
    message,
    instructions,
    isActive,
  ];
}
