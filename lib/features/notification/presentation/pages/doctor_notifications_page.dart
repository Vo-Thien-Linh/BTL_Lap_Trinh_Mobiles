import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../utils/deep_link_handler.dart';

class DoctorNotificationsPage extends StatefulWidget {
  const DoctorNotificationsPage({super.key});

  @override
  State<DoctorNotificationsPage> createState() => _DoctorNotificationsPageState();
}

class _DoctorNotificationsPageState extends State<DoctorNotificationsPage> {
  final _repository = GetIt.instance<NotificationRepository>();
  NotificationCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        title: const Text('Thông báo bác sĩ', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E47B5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _repository.markAllAsRead(user.uid, role: NotificationRecipientRole.doctor),
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _DoctorFilterBar(value: _filter, onChanged: (value) => setState(() => _filter = value)),
          Expanded(
            child: StreamBuilder<List<NotificationEntity>>(
              stream: _repository.watchNotifications(user.uid, role: NotificationRecipientRole.doctor),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = (snapshot.data ?? [])
                    .where((n) => _filter == null || n.category == _filter)
                    .toList();

                if (notifications.isEmpty) {
                  return const Center(child: Text('Không có thông báo nào', style: TextStyle(color: Color(0xFF8A95AC))));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) => _DoctorNotificationCard(
                    notification: notifications[index],
                    onTap: () => _open(notifications[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(NotificationEntity notification) async {
    if (!notification.isRead) await _repository.markAsRead(notification.id);
    if (!mounted) return;

    final deepLink = notification.deepLink;
    if (deepLink != null && deepLink.isNotEmpty) {
      final uri = Uri.tryParse(deepLink);
      if (uri != null) {
        final route = DeepLinkHandler.handleDeepLink(uri);
        if (route != null) {
          Navigator.push(context, route);
          return;
        }
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.body),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }
}

class _DoctorFilterBar extends StatelessWidget {
  final NotificationCategory? value;
  final ValueChanged<NotificationCategory?> onChanged;

  const _DoctorFilterBar({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = <NotificationCategory?, String>{
      null: 'Tất cả',
      NotificationCategory.appointment: 'Lịch khám',
      NotificationCategory.service: 'Dịch vụ',
      NotificationCategory.medical: 'Kết quả',
      NotificationCategory.system: 'Hệ thống',
    };

    return SizedBox(
      height: 62,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final entry = filters.entries.elementAt(index);
          final selected = entry.key == value;
          return ChoiceChip(
            label: Text(entry.value),
            selected: selected,
            onSelected: (_) => onChanged(entry.key),
            selectedColor: const Color(0xFF15233D),
            labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF5A6680), fontWeight: FontWeight.w800),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFDDE6F7)),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: filters.length,
      ),
    );
  }
}

class _DoctorNotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const _DoctorNotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _color(notification.category);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: notification.isRead ? Colors.transparent : color.withOpacity(0.3), width: 1.4),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
              child: Icon(_icon(notification.category), color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(notification.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF15233D)))),
                      if (!notification.isRead) Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF5A6680), height: 1.35)),
                  const SizedBox(height: 9),
                  Text(DateFormat('HH:mm - dd/MM/yyyy', 'vi_VN').format(notification.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF8A95AC), fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _color(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.appointment:
        return const Color(0xFF2563EB);
      case NotificationCategory.medical:
        return const Color(0xFF10B981);
      case NotificationCategory.service:
        return const Color(0xFF0D9488);
      case NotificationCategory.payment:
        return const Color(0xFFF59E0B);
      case NotificationCategory.system:
        return const Color(0xFF64748B);
    }
  }

  IconData _icon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.appointment:
        return Icons.calendar_month_rounded;
      case NotificationCategory.medical:
        return Icons.biotech_rounded;
      case NotificationCategory.service:
        return Icons.medical_services_rounded;
      case NotificationCategory.payment:
        return Icons.receipt_long_rounded;
      case NotificationCategory.system:
        return Icons.info_outline_rounded;
    }
  }
}
