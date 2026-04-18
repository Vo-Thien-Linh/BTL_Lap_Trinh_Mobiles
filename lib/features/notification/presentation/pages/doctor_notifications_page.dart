import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';
import '../../../doctor/presentation/pages/doctor_queue_page.dart';
import '../../../doctor/presentation/pages/doctor_patient_detail_page.dart';

class DoctorNotificationsPage extends StatefulWidget {
  const DoctorNotificationsPage({super.key});

  @override
  State<DoctorNotificationsPage> createState() => _DoctorNotificationsPageState();
}

class _DoctorNotificationsPageState extends State<DoctorNotificationsPage> {
  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Chuyên môn', 'Lịch hẹn', 'Hệ thống'];
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
        .where('doctorId', isEqualTo: uid)
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
      backgroundColor: const Color(0xFFF3F6FC),
      body: uid == null
          ? const Center(child: Text('Vui lòng đăng nhập'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Notifications')
                  .where('doctorId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                _notifications = docs.map((doc) => HospitalNotificationModel.fromFirestore(doc)).toList();
                _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildDoctorHeader(),
                    SliverToBoxAdapter(child: _buildFilterBar()),
                    ..._buildNotificationList(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildDoctorHeader() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return SliverAppBar(
      expandedHeight: 120, // Giảm chiều cao để tập trung vào tiêu đề chính
      pinned: true,
      backgroundColor: const Color(0xFF0E47B5),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      // Đưa chữ Thông báo lên ngang hàng với mũi tên
      title: const Text(
        'Thông báo',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 0.5),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0E47B5), Color(0xFF1A56CE)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Bạn có $unreadCount thông báo chưa đọc',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _markAllAsRead,
          icon: const Icon(Icons.playlist_add_check_rounded, color: Colors.white),
          tooltip: 'Đọc tất cả',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final f = _filters[index];
          final isSelected = _selectedFilter == f;
          return InkWell(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF15233D) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFF15233D).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF5A6680),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildNotificationList() {
    final filtered = _notifications.where((n) {
      if (_selectedFilter == 'Tất cả') return true;
      if (_selectedFilter == 'Chuyên môn') return n.type == NotificationType.medical;
      if (_selectedFilter == 'Lịch hẹn') return n.type == NotificationType.appointment;
      if (_selectedFilter == 'Hệ thống') return n.type == NotificationType.system;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return [
        const SliverFillRemaining(
          child: Center(child: Text('Không có thông báo nào', style: TextStyle(color: Color(0xFF8A95AC)))),
        )
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _DoctorNotificationCard(
              notification: filtered[index],
              onTap: () => _showActionSheet(filtered[index]),
            ),
            childCount: filtered.length,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ];
  }

  void _showActionSheet(HospitalNotificationModel notification) {
    if (!notification.isRead) _markAsRead(notification.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: notification.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(notification.icon, color: notification.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF15233D))),
                      Text(DateFormat('HH:mm - dd/MM/yyyy').format(notification.timestamp), style: const TextStyle(color: Color(0xFF8A95AC), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(notification.body, style: const TextStyle(color: Color(0xFF5A6680), fontSize: 15, height: 1.5)),
            const SizedBox(height: 32),
            if (notification.type == NotificationType.appointment)
              _buildActionButton('MỜI BỆNH NHÂN TIẾP THEO', Icons.groups_rounded, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorQueuePage()));
              }),
            if (notification.type == NotificationType.medical)
              _buildActionButton('MỞ HỒ SƠ BỆNH ÁN', Icons.folder_shared_rounded, () async {
                final patientId = notification.data?['patientId'];
                if (patientId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy mã bệnh nhân')));
                  return;
                }

                // Hiển thị loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF0E47B5))),
                );

                try {
                  final patientDoc = await FirebaseFirestore.instance.collection('users').doc(patientId).get();
                  if (!mounted) return;
                  Navigator.pop(context); // Tắt loading

                  if (patientDoc.exists) {
                    final data = patientDoc.data() as Map<String, dynamic>;
                    
                    // Chuẩn hóa dữ liệu bệnh nhân giống như trong DoctorPatientRecordsPage
                    final patientMap = {
                      'id': patientDoc.id,
                      'name': data['fullName'] ?? data['username'] ?? 'Bệnh nhân',
                      'phone': data['phone'] ?? 'Chưa cập nhật',
                      'gender': data['gender'] ?? 'Chưa rõ',
                      'dob': data['dob'] ?? '--/--/----',
                      'age': _calculateAge(data['dob']),
                      'blood': data['bloodType'] ?? '?',
                      'insurance': data['insuranceNumber'] ?? 'Chưa có',
                    };

                    Navigator.pop(context); // Tắt bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DoctorPatientDetailPage(patient: patientMap)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hồ sơ bệnh nhân không tồn tại')));
                  }
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context); // Tắt loading
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
              child: const Text('ĐÓNG', style: TextStyle(color: Color(0xFF8A95AC), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 0;
    try {
      final parts = dob.split('/');
      if (parts.length == 3) {
        final year = int.parse(parts[2]);
        return DateTime.now().year - year;
      }
    } catch (_) {}
    return 0;
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0E47B5),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }
}

class _DoctorNotificationCard extends StatelessWidget {
  final HospitalNotificationModel notification;
  final VoidCallback onTap;

  const _DoctorNotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: notification.isRead ? const Color(0xFFF9FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: notification.isRead ? Colors.transparent : const Color(0xFF0E47B5).withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15233D).withOpacity(notification.isRead ? 0.02 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(notification.icon, color: notification.color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            notification.type.name.toUpperCase(),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: notification.color, letterSpacing: 1.0),
                          ),
                          Text(
                            _getTimeAgo(notification.timestamp),
                            style: const TextStyle(fontSize: 10, color: Color(0xFF8A95AC)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w900,
                          color: const Color(0xFF15233D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5A6680)),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF0E47B5), shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('dd/MM').format(date);
  }
}
