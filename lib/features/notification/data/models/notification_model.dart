import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType { medical, appointment, system, bill }

class HospitalNotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;
  final Map<String, dynamic>? data;

  HospitalNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.data,
  });

  factory HospitalNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HospitalNotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: _parseType(data['type']),
      isRead: data['isRead'] ?? false,
      data: data,
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'medical':
        return NotificationType.medical;
      case 'appointment':
        return NotificationType.appointment;
      case 'bill':
      case 'payment':
        return NotificationType.bill;
      default:
        return NotificationType.system;
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.medical:
        return Icons.biotech_rounded;
      case NotificationType.appointment:
        return Icons.calendar_month_rounded;
      case NotificationType.bill:
        return Icons.receipt_long_rounded;
      case NotificationType.system:
        return Icons.info_outline_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.medical:
        return const Color(0xFF10B981); // Emerald
      case NotificationType.appointment:
        return const Color(0xFF2563EB); // Blue
      case NotificationType.bill:
        return const Color(0xFFF59E0B); // Amber
      case NotificationType.system:
        return const Color(0xFF64748B); // Slate
    }
  }
}
