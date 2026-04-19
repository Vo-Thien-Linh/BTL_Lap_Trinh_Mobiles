import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../../../appointment/data/models/invoice_models.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Y tế', 'Lịch hẹn', 'Hóa đơn'];
  late List<HospitalNotificationModel> _notifications;

  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final snapshots = await FirebaseFirestore.instance
        .collection('Notifications')
        .where('patientId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: uid != null
            ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
            : const Stream.empty(),
        builder: (context, userSnapshot) {
          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final isDoctor = userData?['role'] == 'doctor';
          final filterField = isDoctor ? 'doctorId' : 'patientId';

          return StreamBuilder<QuerySnapshot>(
            stream: uid != null
                ? FirebaseFirestore.instance
                    .collection('Notifications')
                    .where(filterField, isEqualTo: uid)
                    .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              _notifications = docs.map((doc) => HospitalNotificationModel.fromFirestore(doc)).toList();
              
              // Sort manually to avoid Firestore composite index requirement
              _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildPremiumHeader(),
                  SliverToBoxAdapter(child: _buildFilterBar()),
                  ..._buildGroupedNotificationList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPremiumHeader() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông báo',
              style: TextStyle(
                color: AppColors.textBody,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            if (unreadCount > 0)
              Text(
                'Bạn có $unreadCount thông báo mới chưa đọc',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: _markAllAsRead,
          icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
          tooltip: 'Đánh dấu tất cả đã đọc',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final f = _filters[index];
          final isSelected = _selectedFilter == f;
          return InkWell(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedNotificationList() {
    final filtered = _notifications.where((n) {
      if (_selectedFilter == 'Tất cả') return true;
      if (_selectedFilter == 'Y tế') return n.type == NotificationType.medical;
      if (_selectedFilter == 'Lịch hẹn') return n.type == NotificationType.appointment;
      if (_selectedFilter == 'Hóa đơn') return n.type == NotificationType.bill;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none_rounded, size: 80, color: AppColors.textHint.withOpacity(0.2)),
                const SizedBox(height: 20),
                const Text(
                  'Thư mời trống trải...',
                  style: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn không có thông báo nào vào lúc này',
                  style: TextStyle(color: AppColors.textHint, fontSize: 13),
                ),
              ],
            ),
          ),
        )
      ];
    }

    // Grouping logic
    final Map<String, List<HospitalNotificationModel>> groups = {};
    for (var n in filtered) {
      String groupKey = _getGroupKey(n.timestamp);
      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = [];
      }
      groups[groupKey]!.add(n);
    }

    final List<Widget> slivers = [];
    final keys = ['Hôm nay', 'Hôm qua', 'Trước đó'];

    for (var key in keys) {
      if (groups.containsKey(key)) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                key.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        );

        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final notification = groups[key]![index];
                return _PremiumNotificationCard(
                  notification: notification,
                  onTap: () => _showNotificationDetail(notification),
                  onDismiss: () async {
                    try {
                      await FirebaseFirestore.instance.collection('Notifications').doc(notification.id).delete();
                    } catch (e) {
                      debugPrint('Error deleting notification: $e');
                    }
                  },
                );
              },
              childCount: groups[key]!.length,
            ),
          ),
        );
      }
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 100)));
    return slivers;
  }

  String _getGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Hôm nay';
    if (checkDate == yesterday) return 'Hôm qua';
    return 'Trước đó';
  }

  void _showNotificationDetail(HospitalNotificationModel notification) {
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: notification.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(notification.icon, color: notification.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTypeLabel(notification.type),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: notification.color,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm, dd MMM yyyy').format(notification.timestamp),
                          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                notification.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textBody, height: 1.2),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              Text(
                notification.body,
                style: const TextStyle(fontSize: 16, color: AppColors.textBody, height: 1.6),
              ),
              const SizedBox(height: 40),
              if (notification.type == NotificationType.bill)
                _buildActionButtons(context, 'THANH TOÁN NGAY', Icons.qr_code_scanner_rounded, () async {
                  final invoiceId = notification.data?['invoiceId'];
                  if (invoiceId == null) {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.paymentManagement);
                    return;
                  }

                  // Hiển thị loading khi đang tải dữ liệu hóa đơn
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final doc = await FirebaseFirestore.instance.collection('Invoices').doc(invoiceId).get();
                    if (!mounted) return;
                    Navigator.pop(context); // Close loading

                    if (doc.exists) {
                      final invoice = InvoiceModel.fromFirestore(doc);
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.pushNamed(context, AppRoutes.invoiceDetail, arguments: invoice);
                    } else {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.pushNamed(context, AppRoutes.paymentManagement);
                    }
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                })
              else if (notification.type == NotificationType.medical)
                _buildActionButtons(context, 'XEM KẾT QUẢ', Icons.assignment_rounded, () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.resultsDashboard);
                })
              else if (notification.type == NotificationType.appointment)
                _buildActionButtons(context, 'XEM CHI TIẾT LỊCH HẸN', Icons.calendar_today_rounded, () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.appointmentManagement);
                }),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  foregroundColor: AppColors.textHint,
                ),
                child: const Text('ĐÓNG', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: AppColors.primary.withOpacity(0.4),
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.medical: return 'KẾT QUẢ Y TẾ';
      case NotificationType.appointment: return 'LỊCH HẸN';
      case NotificationType.bill: return 'HÓA ĐƠN';
      case NotificationType.system: return 'HỆ THỐNG';
    }
  }
}

class _PremiumNotificationCard extends StatelessWidget {
  final HospitalNotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _PremiumNotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 32),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: notification.isRead
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
          border: Border.all(
            color: notification.isRead ? AppColors.border.withOpacity(0.5) : AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Priority indicator
              if (!notification.isRead)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(color: notification.color),
                ),
              InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIcon(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCardHeader(),
                            const SizedBox(height: 6),
                            Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notification.isRead ? FontWeight.w700 : FontWeight.w900,
                                color: AppColors.textBody,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                            ),
                            if (!notification.isRead && notification.type != NotificationType.system)
                              _buildQuickActionButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: notification.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(notification.icon, color: notification.color, size: 26),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _getTypeLabel(notification.type),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: notification.color,
            letterSpacing: 0.8,
          ),
        ),
        Text(
          _getTimeAgo(notification.timestamp),
          style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton() {
    String label = 'XEM NGAY';
    if (notification.type == NotificationType.bill) label = 'THANH TOÁN';
    if (notification.type == NotificationType.appointment) label = 'XEM LỊCH';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: notification.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: notification.color),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, size: 8, color: notification.color),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.medical: return 'KẾT QUẢ Y TẾ';
      case NotificationType.appointment: return 'LỊCH HẸN';
      case NotificationType.bill: return 'HÓA ĐƠN';
      case NotificationType.system: return 'HỆ THỐNG';
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    return DateFormat('dd/MM').format(date);
  }
}
