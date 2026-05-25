import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';
import '../datasources/notification_service.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationService notificationService;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.notificationService,
  });

  @override
  Future<Either<Exception, void>> notify(NotificationEntity notification) async {
    try {
      final model = NotificationModel.fromEntity(notification);
      await remoteDataSource.saveNotification(model);

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final shouldShowNow = notification.scheduledAt == null || !notification.scheduledAt!.isAfter(DateTime.now());
      if (notification.sendPush && shouldShowNow && currentUserId == notification.userId) {
        await notificationService.showLocalNotification(
          title: notification.title,
          body: notification.body,
          deepLink: notification.deepLink,
          channel: notification.category.name,
          data: notification.data,
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(Exception('Không thể gửi thông báo: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> saveScheduled(NotificationEntity notification) async {
    try {
      await remoteDataSource.saveNotification(
        NotificationModel.fromEntity(notification.copyWith(deliveryStatus: 'scheduled')),
      );
      return const Right(null);
    } catch (e) {
      return Left(Exception('Không thể lưu thông báo hẹn giờ: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> saveMany(List<NotificationEntity> notifications) async {
    try {
      await remoteDataSource.saveNotifications(notifications.map(NotificationModel.fromEntity).toList());
      return const Right(null);
    } catch (e) {
      return Left(Exception('Không thể lưu danh sách thông báo: $e'));
    }
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications(
    String userId, {
    NotificationRecipientRole? role,
    int limit = 100,
  }) {
    return remoteDataSource
        .watchNotifications(userId, role: role, limit: limit)
        .map((items) => items.map((e) => e.toEntity()).toList());
  }

  @override
  Future<Either<Exception, List<NotificationEntity>>> getNotifications(
    String userId, {
    NotificationRecipientRole? role,
    int limit = 100,
  }) async {
    try {
      final items = await remoteDataSource.getNotifications(userId, role: role, limit: limit);
      return Right(items.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(Exception('Không thể tải thông báo: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> markAsRead(String notificationId) async {
    try {
      await remoteDataSource.markAsRead(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(Exception('Không thể đánh dấu đã đọc: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> markAllAsRead(String userId, {NotificationRecipientRole? role}) async {
    try {
      await remoteDataSource.markAllAsRead(userId, role: role);
      return const Right(null);
    } catch (e) {
      return Left(Exception('Không thể đánh dấu tất cả đã đọc: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> deleteNotification(String notificationId) async {
    try {
      await remoteDataSource.deleteNotification(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(Exception('Không thể xóa thông báo: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> registerCurrentDevice({String? role, String? email}) async {
    try {
      await notificationService.registerCurrentUserDevice(remoteDataSource, role: role, email: email);
      return const Right(null);
    } catch (e) {
      return Left(Exception('Không thể lưu FCM token: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> scheduleAppointmentReminders({
    required String appointmentId,
    required String userId,
    required DateTime appointmentTime,
    required String doctorName,
    required String departmentId,
    required String departmentName,
    String? patientEmail,
    String? deepLink,
  }) async {
    try {
      final template = await remoteDataSource.getPreparationTemplate(departmentId);
      final preparationText = template == null || template.instructions.isEmpty
          ? 'Vui lòng mang giấy tờ tùy thân, bảo hiểm y tế nếu có và đến sớm 15 phút.'
          : '${template.message} ${template.instructions.join(' ')}';

      final link = deepLink ?? '/appointment-detail?id=$appointmentId';
      final now = DateTime.now();
      final scheduled = <NotificationEntity>[];

      void addScheduled({
        required String suffix,
        required DateTime at,
        required NotificationType type,
        required NotificationCategory category,
        required String title,
        required String body,
        bool email = false,
      }) {
        if (!at.isAfter(now)) return;
        scheduled.add(NotificationEntity(
          id: '${appointmentId}_$suffix',
          userId: userId,
          patientId: userId,
          doctorId: null,
          recipientRole: NotificationRecipientRole.patient,
          type: type,
          category: category,
          title: title,
          body: body,
          data: {
            'appointmentId': appointmentId,
            'doctorName': doctorName,
            'departmentId': departmentId,
            'departmentName': departmentName,
            'appointmentTime': appointmentTime.toIso8601String(),
          },
          createdAt: now,
          scheduledAt: at,
          deepLink: link,
          sendPush: true,
          sendEmail: email,
          email: patientEmail,
          deliveryStatus: 'scheduled',
        ));
      }

      addScheduled(
        suffix: 'reminder_24h',
        at: appointmentTime.subtract(const Duration(hours: 24)),
        type: NotificationType.appointmentReminder24h,
        category: NotificationCategory.appointment,
        title: 'Nhắc lịch khám ngày mai',
        body: 'Bạn có lịch khám với BS. $doctorName vào ${_formatDateTime(appointmentTime)}.',
        email: true,
      );

      addScheduled(
        suffix: 'preparation',
        at: appointmentTime.subtract(const Duration(hours: 24)),
        type: NotificationType.preparationInstruction,
        category: NotificationCategory.medical,
        title: 'Hướng dẫn chuẩn bị trước khám',
        body: preparationText,
      );

      addScheduled(
        suffix: 'reminder_1h',
        at: appointmentTime.subtract(const Duration(hours: 1)),
        type: NotificationType.appointmentReminder1h,
        category: NotificationCategory.appointment,
        title: 'Còn 1 giờ tới lịch khám',
        body: 'Vui lòng chuẩn bị giấy tờ và đến đúng giờ tại khoa $departmentName.',
      );

      if (scheduled.isNotEmpty) {
        await remoteDataSource.saveNotifications(scheduled.map(NotificationModel.fromEntity).toList());
      }

      if (FirebaseAuth.instance.currentUser?.uid == userId) {
        await notificationService.scheduleAppointmentLocalReminders(
          appointmentId: appointmentId,
          appointmentTime: appointmentTime,
          doctorName: doctorName,
          departmentName: departmentName,
          preparationText: preparationText,
          deepLink: link,
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(Exception('Không thể lập lịch nhắc hẹn: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> cancelAppointmentNotifications(String appointmentId) async {
    try {
      await remoteDataSource.cancelAppointmentScheduledNotifications(appointmentId);
      await notificationService.cancelAppointmentLocalReminders(appointmentId);
      return const Right(null);
    } catch (e) {
      return Left(Exception('Không thể hủy thông báo lịch hẹn: $e'));
    }
  }

  @override
  Future<Either<Exception, List<NotificationTemplateEntity>>> getNotificationTemplatesByDepartment(String departmentId) async {
    try {
      final items = await remoteDataSource.getNotificationTemplatesByDepartment(departmentId);
      return Right(items.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(Exception('Không thể tải mẫu thông báo: $e'));
    }
  }

  @override
  Future<Either<Exception, NotificationTemplateEntity?>> getPreparationTemplate(String departmentId) async {
    try {
      final item = await remoteDataSource.getPreparationTemplate(departmentId);
      return Right(item?.toEntity());
    } catch (e) {
      return Left(Exception('Không thể tải hướng dẫn chuẩn bị: $e'));
    }
  }

  String _formatDateTime(DateTime value) {
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} lúc ${value.hour}:$minute';
  }
}
