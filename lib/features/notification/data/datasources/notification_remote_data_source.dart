import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';
import '../../../../services/firestore_sequence_service.dart';

class NotificationRemoteDataSource {
  static const String notificationsCollection = 'Notifications';
  static const String templatesCollection = 'notification_templates';

  final FirebaseFirestore firestore;

  NotificationRemoteDataSource(this.firestore);

  Future<void> saveNotification(NotificationModel notification) async {
    final payload = notification.toFirestore();
    payload['notificationCode'] ??= await FirestoreSequenceService(
      firestore: firestore,
    ).generateNextCode('notifications');
    await firestore
        .collection(notificationsCollection)
        .doc(notification.id)
        .set(payload, SetOptions(merge: true));
  }

  Future<void> saveNotifications(List<NotificationModel> notifications) async {
    final batch = firestore.batch();
    final sequenceService = FirestoreSequenceService(firestore: firestore);
    for (final notification in notifications) {
      final ref = firestore
          .collection(notificationsCollection)
          .doc(notification.id);
      final payload = notification.toFirestore();
      payload['notificationCode'] ??= await sequenceService.generateNextCode(
        'notifications',
      );
      batch.set(ref, payload, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Stream<List<NotificationModel>> watchNotifications(
    String userId, {
    NotificationRecipientRole? role,
    int limit = 100,
  }) {
    Query query = firestore
        .collection(notificationsCollection)
        .where('userId', isEqualTo: userId);
    if (role != null) {
      query = query.where('recipientRole', isEqualTo: role.name);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      final now = DateTime.now();
      final items = snapshot.docs
          .map(NotificationModel.fromFirestore)
          .where((n) => n.scheduledAt == null || !n.scheduledAt!.isAfter(now))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<List<NotificationModel>> getNotifications(
    String userId, {
    NotificationRecipientRole? role,
    int limit = 100,
  }) async {
    Query query = firestore
        .collection(notificationsCollection)
        .where('userId', isEqualTo: userId);
    if (role != null) {
      query = query.where('recipientRole', isEqualTo: role.name);
    }

    final snapshot = await query.limit(limit).get();

    final now = DateTime.now();
    final items = snapshot.docs
        .map(NotificationModel.fromFirestore)
        .where((n) => n.scheduledAt == null || !n.scheduledAt!.isAfter(now))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> markAsRead(String notificationId) async {
    await firestore
        .collection(notificationsCollection)
        .doc(notificationId)
        .update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> markAllAsRead(
    String userId, {
    NotificationRecipientRole? role,
  }) async {
    Query query = firestore
        .collection(notificationsCollection)
        .where('userId', isEqualTo: userId);
    if (role != null) {
      query = query.where('recipientRole', isEqualTo: role.name);
    }

    final snapshot = await query.where('isRead', isEqualTo: false).get();

    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await firestore
        .collection(notificationsCollection)
        .doc(notificationId)
        .delete();
  }

  Future<void> cancelAppointmentScheduledNotifications(
    String appointmentId,
  ) async {
    final snapshot = await firestore
        .collection(notificationsCollection)
        .where('data.appointmentId', isEqualTo: appointmentId)
        .where('deliveryStatus', isEqualTo: 'scheduled')
        .get();

    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'deliveryStatus': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> saveDeviceToken({
    required String userId,
    required String token,
    String? role,
    String? email,
  }) async {
    final payload = {
      'token': token,
      'userId': userId,
      'role': role,
      'email': email,
      'platformUpdatedAt': FieldValue.serverTimestamp(),
      'active': true,
    };

    await firestore
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .doc(token)
        .set(payload, SetOptions(merge: true));
  }

  Future<NotificationTemplateModel?> getPreparationTemplate(
    String departmentId,
  ) async {
    final exact = await firestore
        .collection(templatesCollection)
        .where('departmentId', isEqualTo: departmentId)
        .where('templateType', isEqualTo: 'preparation')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (exact.docs.isNotEmpty)
      return NotificationTemplateModel.fromFirestore(exact.docs.first);

    final fallback = await firestore
        .collection(templatesCollection)
        .where('departmentId', isEqualTo: 'default')
        .where('templateType', isEqualTo: 'preparation')
        .limit(1)
        .get();

    if (fallback.docs.isNotEmpty)
      return NotificationTemplateModel.fromFirestore(fallback.docs.first);
    return null;
  }

  Future<List<NotificationTemplateModel>> getNotificationTemplatesByDepartment(
    String departmentId,
  ) async {
    final snapshot = await firestore
        .collection(templatesCollection)
        .where('departmentId', isEqualTo: departmentId)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map(NotificationTemplateModel.fromFirestore).toList();
  }

  Future<void> createNotificationTemplate(
    NotificationTemplateModel template,
  ) async {
    await firestore
        .collection(templatesCollection)
        .doc(template.id)
        .set(template.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updateNotificationTemplate(
    NotificationTemplateModel template,
  ) async {
    await createNotificationTemplate(template);
  }
}
