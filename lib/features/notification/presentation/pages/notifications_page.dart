import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../utils/deep_link_handler.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _repository = GetIt.instance<NotificationRepository>();
  NotificationCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF15233D),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _repository.markAllAsRead(user.uid, role: NotificationRecipientRole.patient),
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Đánh dấu tất cả đã đọc',
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(value: _filter, onChanged: (value) => setState(() => _filter = value)),
          Expanded(
            child: StreamBuilder<List<NotificationEntity>>(
              stream: _repository.watchNotifications(user.uid, role: NotificationRecipientRole.patient),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = (snapshot.data ?? [])
                    .where((n) => _filter == null || n.category == _filter)
                    .toList();

                if (notifications.isEmpty) {
                  return const _EmptyNotificationView();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return _NotificationCard(
                      notification: item,
                      onTap: () => _openNotification(item),
                      onDelete: () => _repository.deleteNotification(item.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNotification(NotificationEntity notification) async {
    if (!notification.isRead) {
      await _repository.markAsRead(notification.id);
    }

    if (!mounted) return;
    if (notification.deepLink != null && notification.deepLink!.isNotEmpty) {
      final uri = Uri.tryParse(notification.deepLink!);
      if (uri != null) {
        final route = DeepLinkHandler.handleDeepLink(uri);
        if (route != null) {
          Navigator.of(context).push(route);
          return;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
            const SizedBox(height: 12),
            Text(notification.body, style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF5A6680))),
            const SizedBox(height: 18),
            Text(DateFormat('HH:mm, dd/MM/yyyy', 'vi_VN').format(notification.createdAt), style: const TextStyle(color: Color(0xFF8A95AC))),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final NotificationCategory? value;
  final ValueChanged<NotificationCategory?> onChanged;

  const _FilterBar({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = <NotificationCategory?, String>{
      null: 'Tất cả',
      NotificationCategory.appointment: 'Lịch hẹn',
      NotificationCategory.medical: 'Y tế',
      NotificationCategory.service: 'Dịch vụ',
      NotificationCategory.payment: 'Hóa đơn',
      NotificationCategory.system: 'Hệ thống',
    };

    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final entry = filters.entries.elementAt(index);
          final selected = entry.key == value;
          return ChoiceChip(
            label: Text(entry.value),
            selected: selected,
            onSelected: (_) => onChanged(entry.key),
            selectedColor: const Color(0xFF0D9488),
            labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF5A6680), fontWeight: FontWeight.w800),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFDDE6F7)),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({required this.notification, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _color(notification.category);
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: notification.isRead ? Colors.transparent : color.withOpacity(0.35), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(_icon(notification.category), color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead ? FontWeight.w700 : FontWeight.w900,
                              color: const Color(0xFF15233D),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF5A6680))),
                    const SizedBox(height: 9),
                    Text(DateFormat('HH:mm - dd/MM/yyyy', 'vi_VN').format(notification.createdAt), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8A95AC))),
                  ],
                ),
              ),
            ],
          ),
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

class _EmptyNotificationView extends StatelessWidget {
  const _EmptyNotificationView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded, size: 78, color: Color(0xFFCBD5E1)),
          SizedBox(height: 14),
          Text('Chưa có thông báo', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF5A6680))),
        ],
      ),
    );
  }
}
