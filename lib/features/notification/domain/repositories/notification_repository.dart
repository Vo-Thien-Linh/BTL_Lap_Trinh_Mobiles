import 'package:dartz/dartz.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<Exception, void>> notify(NotificationEntity notification);

  Future<Either<Exception, void>> saveScheduled(NotificationEntity notification);

  Future<Either<Exception, void>> saveMany(List<NotificationEntity> notifications);

  Stream<List<NotificationEntity>> watchNotifications(
    String userId, {
    NotificationRecipientRole? role,
    int limit = 100,
  });

  Future<Either<Exception, List<NotificationEntity>>> getNotifications(
    String userId, {
    NotificationRecipientRole? role,
    int limit = 100,
  });

  Future<Either<Exception, void>> markAsRead(String notificationId);

  Future<Either<Exception, void>> markAllAsRead(
    String userId, {
    NotificationRecipientRole? role,
  });

  Future<Either<Exception, void>> deleteNotification(String notificationId);

  Future<Either<Exception, void>> registerCurrentDevice({
    String? role,
    String? email,
  });

  Future<Either<Exception, void>> scheduleAppointmentReminders({
    required String appointmentId,
    required String userId,
    required DateTime appointmentTime,
    required String doctorName,
    required String departmentId,
    required String departmentName,
    String? patientEmail,
    String? deepLink,
  });

  Future<Either<Exception, void>> cancelAppointmentNotifications(String appointmentId);

  Future<Either<Exception, List<NotificationTemplateEntity>>> getNotificationTemplatesByDepartment(String departmentId);

  Future<Either<Exception, NotificationTemplateEntity?>> getPreparationTemplate(String departmentId);
}
