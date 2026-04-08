import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../config/service_locator.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import 'doctor_appointment_detail_page.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage>
    with SingleTickerProviderStateMixin {
  final LogoutUsecase _logoutUsecase = getIt<LogoutUsecase>();

  late final TabController _tabController;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);

    try {
      await _logoutUsecase();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đăng xuất. Vui lòng thử lại.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<_DoctorContext?> _loadDoctorContext() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final userData = userDoc.data() ?? {};
    final doctorName =
        (userData['fullName'] ?? userData['username'] ?? 'Bác sĩ') as String;

    final doctorSnapshot = await FirebaseFirestore.instance
        .collection('Doctors')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();

    if (doctorSnapshot.docs.isEmpty) {
      return _DoctorContext(
        doctorId: '',
        doctorName: doctorName,
        specialization: 'Đa khoa',
      );
    }

    final doctorDoc = doctorSnapshot.docs.first;
    final data = doctorDoc.data();

    return _DoctorContext(
      doctorId: doctorDoc.id,
      doctorName: (data['name'] ?? doctorName) as String,
      specialization: (data['specialization'] ?? 'Đa khoa') as String,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _doctorAppointmentsStream(
    String doctorId,
  ) {
    if (doctorId.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('Appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 74,
        title: const Text(
          'Cổng Bác sĩ',
          style: TextStyle(
            color: Color(0xFF13223E),
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoggingOut ? null : _handleLogout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded, color: Color(0xFFC62828)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder<_DoctorContext?>(
        future: _loadDoctorContext(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doctor = snapshot.data;
          if (doctor == null) {
            return const Center(
              child: Text('Không tìm thấy thông tin bác sĩ.'),
            );
          }

          return Column(
            children: [
              _buildDoctorHeader(doctor),
              const SizedBox(height: 12),
              _buildTabBar(),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(doctor),
                    _buildScheduleTab(doctor),
                    _buildPatientsTab(doctor),
                    _buildProfileTab(doctor),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDoctorHeader(_DoctorContext doctor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E47B5), Color(0xFF2267D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E47B5).withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFD9E7FF),
            child: Icon(
              Icons.medical_services_rounded,
              color: Color(0xFF0E47B5),
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.doctorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chuyên ngành: ${doctor.specialization}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: const Color(0xFF0E47B5),
        unselectedLabelColor: const Color(0xFF5B6780),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Lịch khám'),
          Tab(text: 'Bệnh nhân'),
          Tab(text: 'Hồ sơ'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(_DoctorContext doctor) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _doctorAppointmentsStream(doctor.doctorId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        final todayAppointments = docs.where((doc) {
          final ts = doc.data()['appointmentDate'];
          if (ts is! Timestamp) return false;
          final date = ts.toDate();
          return !date.isBefore(todayStart) && date.isBefore(todayEnd);
        }).toList();

        final waitingPatients = todayAppointments.where((doc) {
          final status = (doc.data()['status'] ?? '').toString().toLowerCase();
          return status == 'pending' || status == 'confirmed';
        }).length;

        final upcoming = docs.where((doc) {
          final ts = doc.data()['appointmentDate'];
          if (ts is! Timestamp) return false;
          return ts.toDate().isAfter(now);
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          children: [
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    title: 'Lịch hôm nay',
                    value: '${todayAppointments.length}',
                    color: const Color(0xFF1457CC),
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    title: 'Đang chờ',
                    value: '$waitingPatients',
                    color: const Color(0xFF0E9F6E),
                    icon: Icons.groups_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Lịch sắp tới',
              child: upcoming.isEmpty
                  ? const Text('Chưa có lịch sắp tới.')
                  : Column(
                      children: upcoming.take(4).map((doc) {
                        final data = doc.data();
                        final patientName =
                            (data['patientName'] ?? 'Bệnh nhân') as String;
                        final date = (data['appointmentDate'] as Timestamp?)
                            ?.toDate();
                        final dateText = date == null
                            ? 'Chưa có ngày'
                            : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                        return _listTileInfo(
                          icon: Icons.event_available_rounded,
                          title: patientName,
                          subtitle: dateText,
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Tác vụ nhanh',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _QuickActionChip(
                    label: 'Nhập kết quả',
                    icon: Icons.edit_note_rounded,
                  ),
                  _QuickActionChip(
                    label: 'Kê đơn thuốc',
                    icon: Icons.medication_rounded,
                  ),
                  _QuickActionChip(
                    label: 'Lịch làm việc',
                    icon: Icons.schedule_rounded,
                  ),
                  _QuickActionChip(
                    label: 'Danh sách bệnh nhân',
                    icon: Icons.badge_rounded,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduleTab(_DoctorContext doctor) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _doctorAppointmentsStream(doctor.doctorId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final sorted = [...docs]
          ..sort((a, b) {
            final da =
                (a.data()['appointmentDate'] as Timestamp?)?.toDate() ??
                DateTime(1900);
            final db =
                (b.data()['appointmentDate'] as Timestamp?)?.toDate() ??
                DateTime(1900);
            return da.compareTo(db);
          });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final data = sorted[index].data();
            final patientName = (data['patientName'] ?? 'Bệnh nhân') as String;
            final status = (data['status'] ?? 'pending').toString();
            final date = (data['appointmentDate'] as Timestamp?)?.toDate();
            final timeText = date == null
                ? 'Chưa có thời gian'
                : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7ECF6)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DoctorAppointmentDetailPage(
                        appointmentId: sorted[index].id,
                        initialData: data,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFDCE8FF),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF1654C0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15233D),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5A6680),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _statusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => DoctorAppointmentDetailPage(
                                      appointmentId: sorted[index].id,
                                      initialData: data,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined, size: 16),
                              label: const Text('Xem hồ sơ'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => DoctorAppointmentDetailPage(
                                      appointmentId: sorted[index].id,
                                      initialData: data,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1457CC),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(
                                Icons.medical_services_outlined,
                                size: 16,
                              ),
                              label: const Text('Bắt đầu khám'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPatientsTab(_DoctorContext doctor) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _doctorAppointmentsStream(doctor.doctorId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final uniquePatients = <String, Map<String, dynamic>>{};

        for (final doc in docs) {
          final data = doc.data();
          final patientId = (data['patientId'] ?? '').toString();
          if (patientId.isEmpty) continue;
          uniquePatients[patientId] = data;
        }

        final items = uniquePatients.values.toList();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final data = items[index];
            final name = (data['patientName'] ?? 'Bệnh nhân') as String;
            final symptoms = (data['symptoms'] ?? 'Chưa có mô tả triệu chứng')
                .toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7ECF6)),
              ),
              child: _listTileInfo(
                icon: Icons.badge_rounded,
                title: name,
                subtitle: symptoms,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab(_DoctorContext doctor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      children: [
        _sectionCard(
          title: 'Hồ sơ bác sĩ',
          child: Column(
            children: [
              _profileRow('Họ tên', doctor.doctorName),
              _profileRow('Chuyên khoa', doctor.specialization),
              _profileRow(
                'Mã bác sĩ',
                doctor.doctorId.isEmpty ? 'Chưa cập nhật' : doctor.doctorId,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Chức năng',
          child: Column(
            children: const [
              _ActionLine(
                icon: Icons.edit_note_rounded,
                label: 'Nhập kết quả khám',
              ),
              _ActionLine(
                icon: Icons.medication_outlined,
                label: 'Kê đơn thuốc',
              ),
              _ActionLine(
                icon: Icons.schedule_outlined,
                label: 'Quản lý lịch làm việc',
              ),
              _ActionLine(
                icon: Icons.lock_outline_rounded,
                label: 'Đổi mật khẩu',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF122241),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF5A6680), fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF13223E),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _listTileInfo({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF1A56C1)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF162641),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF5A6680),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final value = status.toLowerCase();
    late final Color color;
    late final String label;

    if (value == 'completed') {
      color = const Color(0xFF0E9F6E);
      label = 'Đã khám';
    } else if (value == 'cancelled') {
      color = const Color(0xFFDE3A3A);
      label = 'Đã huỷ';
    } else if (value == 'confirmed') {
      color = const Color(0xFF1565C0);
      label = 'Đã xác nhận';
    } else {
      color = const Color(0xFFB26A00);
      label = 'Chờ khám';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5A6680),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF13223E),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorContext {
  const _DoctorContext({
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
  });

  final String doctorId;
  final String doctorName;
  final String specialization;
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0E47B5)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0E47B5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionLine extends StatelessWidget {
  const _ActionLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2459BF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF193257),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A95AC)),
        ],
      ),
    );
  }
}
