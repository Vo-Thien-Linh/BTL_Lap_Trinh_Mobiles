import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';

enum HospitalNotificationType { medical, appointment, system, bill, service }

class HospitalNotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final HospitalNotificationType type;
  bool isRead;
  final Map<String, dynamic> data;

  HospitalNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.data = const {},
  });

  factory HospitalNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final raw = (doc.data() as Map<String, dynamic>?) ?? {};
    return HospitalNotificationModel(
      id: doc.id,
      title: raw['title']?.toString() ?? '',
      body: (raw['body'] ?? raw['content'] ?? raw['message'] ?? '').toString(),
      timestamp: _readDate(raw['timestamp']) ??
          _readDate(raw['createdAt']) ??
          _readDate(raw['scheduledAt']) ??
          DateTime.now(),
      type: _parseHospitalType(raw['category'] ?? raw['type']),
      isRead: raw['isRead'] == true,
      data: raw,
    );
  }

  static HospitalNotificationType _parseHospitalType(dynamic value) {
    final type = value?.toString() ?? '';
    if (type.contains('payment') || type.contains('bill') || type.contains('invoice')) {
      return HospitalNotificationType.bill;
    }
    if (type.contains('appointment')) return HospitalNotificationType.appointment;
    if (type.contains('service')) return HospitalNotificationType.service;
    if (type.contains('medical') || type.contains('examination') || type.contains('result') || type.contains('medication')) {
      return HospitalNotificationType.medical;
    }
    return HospitalNotificationType.system;
  }

  IconData get icon {
    switch (type) {
      case HospitalNotificationType.medical:
        return Icons.biotech_rounded;
      case HospitalNotificationType.appointment:
        return Icons.calendar_month_rounded;
      case HospitalNotificationType.bill:
        return Icons.receipt_long_rounded;
      case HospitalNotificationType.service:
        return Icons.medical_services_rounded;
      case HospitalNotificationType.system:
        return Icons.info_outline_rounded;
    }
  }

  Color get color {
    switch (type) {
      case HospitalNotificationType.medical:
        return const Color(0xFF10B981);
      case HospitalNotificationType.appointment:
        return const Color(0xFF2563EB);
      case HospitalNotificationType.bill:
        return const Color(0xFFF59E0B);
      case HospitalNotificationType.service:
        return const Color(0xFF0D9488);
      case HospitalNotificationType.system:
        return const Color(0xFF64748B);
    }
  }
}

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String? patientId;
  final String? doctorId;
  final String recipientRole;
  final String type;
  final String category;
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
  final String deliveryStatus;
  final DateTime? deliveredAt;

  const NotificationModel({
    required this.id,
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

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      patientId: entity.patientId,
      doctorId: entity.doctorId,
      recipientRole: entity.recipientRole.name,
      type: entity.type.name,
      category: entity.category.name,
      title: entity.title,
      body: entity.body,
      data: entity.data,
      createdAt: entity.createdAt,
      scheduledAt: entity.scheduledAt,
      isRead: entity.isRead,
      deepLink: entity.deepLink,
      sendPush: entity.sendPush,
      sendEmail: entity.sendEmail,
      email: entity.email,
      deliveryStatus: entity.deliveryStatus,
      deliveredAt: entity.deliveredAt,
    );
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final raw = (doc.data() as Map<String, dynamic>?) ?? {};
    return NotificationModel(
      id: doc.id,
      userId: (raw['userId'] ?? raw['patientId'] ?? raw['doctorId'] ?? '').toString(),
      patientId: raw['patientId']?.toString(),
      doctorId: raw['doctorId']?.toString(),
      recipientRole: (raw['recipientRole'] ?? _inferRole(raw)).toString(),
      type: (raw['type'] ?? 'system').toString(),
      category: (raw['category'] ?? _inferCategory(raw['type'])).toString(),
      title: raw['title']?.toString() ?? '',
      body: (raw['body'] ?? raw['content'] ?? raw['message'] ?? '').toString(),
      data: Map<String, dynamic>.from((raw['data'] as Map?) ?? raw),
      createdAt: _readDate(raw['createdAt']) ?? _readDate(raw['timestamp']) ?? DateTime.now(),
      scheduledAt: _readDate(raw['scheduledAt']),
      isRead: raw['isRead'] == true,
      deepLink: raw['deepLink']?.toString(),
      sendPush: raw['sendPush'] != false,
      sendEmail: raw['sendEmail'] == true,
      email: raw['email']?.toString(),
      deliveryStatus: (raw['deliveryStatus'] ?? 'pending').toString(),
      deliveredAt: _readDate(raw['deliveredAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'id': id,
      'userId': userId,
      'patientId': patientId,
      'doctorId': doctorId,
      'recipientRole': recipientRole,
      'type': type,
      'category': category,
      'title': title,
      'body': body,
      'content': body, // giữ tương thích với UI cũ
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'timestamp': Timestamp.fromDate(createdAt), // giữ tương thích với UI cũ
      'scheduledAt': scheduledAt == null ? null : Timestamp.fromDate(scheduledAt!),
      'isRead': isRead,
      'deepLink': deepLink,
      'sendPush': sendPush,
      'sendEmail': sendEmail,
      'email': email,
      'deliveryStatus': deliveryStatus,
      'deliveredAt': deliveredAt == null ? null : Timestamp.fromDate(deliveredAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    map.removeWhere((_, value) => value == null);
    return map;
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      userId: userId,
      patientId: patientId,
      doctorId: doctorId,
      recipientRole: _roleFromString(recipientRole),
      type: _typeFromString(type),
      category: _categoryFromString(category),
      title: title,
      body: body,
      data: data,
      createdAt: createdAt,
      scheduledAt: scheduledAt,
      isRead: isRead,
      deepLink: deepLink,
      sendPush: sendPush,
      sendEmail: sendEmail,
      email: email,
      deliveryStatus: deliveryStatus,
      deliveredAt: deliveredAt,
    );
  }

  static NotificationRecipientRole _roleFromString(String value) {
    return NotificationRecipientRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationRecipientRole.patient,
    );
  }

  static NotificationType _typeFromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.system,
    );
  }

  static NotificationCategory _categoryFromString(String value) {
    return NotificationCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationCategory.system,
    );
  }

  @override
  List<Object?> get props => [
        id,
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

class NotificationTemplateModel extends Equatable {
  final String id;
  final String departmentId;
  final String departmentName;
  final String templateType;
  final String title;
  final String message;
  final List<String> instructions;
  final bool isActive;

  const NotificationTemplateModel({
    required this.id,
    required this.departmentId,
    required this.departmentName,
    required this.templateType,
    required this.title,
    required this.message,
    required this.instructions,
    this.isActive = true,
  });

  factory NotificationTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final raw = (doc.data() as Map<String, dynamic>?) ?? {};
    return NotificationTemplateModel(
      id: doc.id,
      departmentId: raw['departmentId']?.toString() ?? '',
      departmentName: raw['departmentName']?.toString() ?? '',
      templateType: raw['templateType']?.toString() ?? 'preparation',
      title: raw['title']?.toString() ?? '',
      message: raw['message']?.toString() ?? '',
      instructions: List<String>.from((raw['instructions'] as List?) ?? const []),
      isActive: raw['isActive'] != false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'departmentId': departmentId,
        'departmentName': departmentName,
        'templateType': templateType,
        'title': title,
        'message': message,
        'instructions': instructions,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  NotificationTemplateEntity toEntity() => NotificationTemplateEntity(
        id: id,
        departmentId: departmentId,
        departmentName: departmentName,
        templateType: templateType,
        title: title,
        message: message,
        instructions: instructions,
        isActive: isActive,
      );

  @override
  List<Object?> get props => [id, departmentId, departmentName, templateType, title, message, instructions, isActive];
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _inferRole(Map<String, dynamic> raw) {
  if (raw['doctorId'] != null && raw['patientId'] == null) return 'doctor';
  return 'patient';
}

String _inferCategory(dynamic type) {
  final value = type?.toString() ?? '';
  if (value.contains('payment')) return 'payment';
  if (value.contains('appointment')) return 'appointment';
  if (value.contains('service')) return 'service';
  if (value.contains('result') || value.contains('examination') || value.contains('medication')) return 'medical';
  return 'system';
}
