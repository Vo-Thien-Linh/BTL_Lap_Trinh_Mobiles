import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../config/service_locator.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import 'doctor_queue_page.dart';
import 'doctor_service_queue_page.dart';
import 'doctor_schedule_page.dart';
import 'doctor_patient_records_page.dart';
import 'doctor_prescription_builder_page.dart';
import 'doctor_examination_list_page.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  bool _isLoggingOut = false;
  bool _isOnline = true; // Trạng thái hoạt động thực tế

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      await getIt<LogoutUsecase>()();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: authUser != null
          ? FirebaseFirestore.instance.collection('users').doc(authUser.uid).snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        String name = 'Bác sĩ';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['fullName'] ?? data['username'] ?? 'Bác sĩ';
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Stack(
            children: [
              // Vibrant Blue Premium Background
              Container(
                height: 380,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A56CE), Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ),
                ),
              ),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildCommandHeader(name),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildNextPatientSpotlight(),
                          const SizedBox(height: 24),
                          _buildSmartMetricsRow(),
                          const SizedBox(height: 32),
                          _buildSectionHeader('CÔNG CỤ ĐIỀU HÀNH'),
                          const SizedBox(height: 16),
                          _buildModernGrid(),
                          const SizedBox(height: 32),
                          _buildSectionHeader('LỊCH TRÌNH KHÁM'),
                          const SizedBox(height: 8),
                          _buildMiniTimeline(),
                          const SizedBox(height: 32),
                          _buildSectionHeader('HIỆU SUẤT TRỰC'),
                          const SizedBox(height: 16),
                          _buildPerformanceSnapshot(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommandHeader(String name) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      stretch: true,
      title: const Text('CLINICAL COMMAND CENTER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2.5, color: Colors.white70)),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(24, 110, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isOnline ? 'SẴN SÀNG KHÁM BỆNH,' : 'ĐANG NGOẠI TUYẾN,', 
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                        ),
                        const SizedBox(height: 4),
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                  _buildStatusToggle(),
                ],
              ),
              const SizedBox(height: 28),
              _buildSmartSearchTrigger(),
            ],
          ),
        ),
      ),
      actions: [
        _buildHeaderIcon(
          icon: Icons.notifications_none_rounded,
          onTap: () => Navigator.pushNamed(context, AppRoutes.doctorNotifications),
          badge: true,
        ),
        _buildHeaderIcon(
          icon: Icons.refresh_rounded,
          onTap: () => _handleRefresh(context),
        ),
        _buildHeaderIcon(
          icon: Icons.power_settings_new_rounded,
          onTap: _isLoggingOut ? null : _handleLogout,
          color: const Color(0xFFFFE4E4),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildStatusToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isOnline = !_isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _isOnline ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
          boxShadow: [
            if (_isOnline) BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: _isOnline ? const Color(0xFF4ADE80) : Colors.white54,
                shape: BoxShape.circle,
                boxShadow: [_isOnline ? const BoxShadow(color: Color(0xFF4ADE80), blurRadius: 6, spreadRadius: 2) : const BoxShadow()]
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isOnline ? 'ONLINE' : 'OFFLINE', 
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon({required IconData icon, VoidCallback? onTap, bool badge = false, Color color = Colors.white}) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
      child: IconButton(
        onPressed: onTap,
        icon: badge ? Badge(backgroundColor: const Color(0xFFEF4444), smallSize: 8, child: Icon(icon, color: color, size: 20)) : Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _handleRefresh(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang cập nhật dữ liệu...'), duration: Duration(seconds: 1)));
    if (mounted) setState(() {});
  }

  Widget _buildSmartSearchTrigger() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.doctorSearch),
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25), 
                borderRadius: BorderRadius.circular(18), 
                border: Border.all(color: Colors.white.withOpacity(0.35))
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 14),
                  Text('Tìm kiếm nhanh bệnh án...', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextPatientSpotlight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: const Color(0xFF0E47B5).withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 16))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.play_circle_filled_rounded, color: Color(0xFF0E47B5), size: 18),
              SizedBox(width: 8),
              Text('BỆNH NHÂN TIẾP THEO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF0E47B5), letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF0F5FF),
                child: const Icon(Icons.person_rounded, color: Color(0xFF0E47B5)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trần Thị Bình', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
                    Text('29 tuổi • Nữ • Khám tức ngực', style: TextStyle(fontSize: 12, color: Color(0xFF5A6680))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.flash_on_rounded, color: Color(0xFFEF4444), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _spotlightVital('Huyết áp', '160/100', Colors.red),
              _spotlightVital('Nhịp tim', '112 bpm', Colors.orange),
              _spotlightVital('SpO2', '92%', Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorQueuePage())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E47B5),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: const Text('MỜI VÀO PHÒNG KHÁM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _spotlightVital(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8A95AC))),
      ],
    );
  }

  Widget _buildSmartMetricsRow() {
    return Row(
      children: [
        _metricCard('CHỜ KHÁM', '12', const Color(0xFF0E47B5), Icons.hourglass_empty_rounded),
        const SizedBox(width: 14),
        _metricCard('KHẨN CẤP', '02', const Color(0xFFEF4444), Icons.notification_important_rounded, hasPulse: true),
        const SizedBox(width: 14),
        _metricCard('ĐÃ KHÁM', '24', const Color(0xFF10B981), Icons.task_alt_rounded),
      ],
    );
  }

  Widget _metricCard(String label, String val, Color color, IconData icon, {bool hasPulse = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.08))),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 12),
            Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC), letterSpacing: 1.5));
  }

  Widget _buildModernGrid() {
    final tools = [
      {'icon': Icons.groups_rounded, 'label': 'Hàng đợi', 'color': const Color(0xFF0E47B5), 'target': const DoctorQueuePage()},
      {'icon': Icons.medical_services_rounded, 'label': 'Khám bệnh', 'color': const Color(0xFF1A56CE), 'target': const DoctorExaminationListPage()},
      {'icon': Icons.biotech_rounded, 'label': 'Xét nghiệm', 'color': const Color(0xFF10B981), 'target': const DoctorServiceQueuePage()},
      {'icon': Icons.event_note_rounded, 'label': 'Lịch làm', 'color': const Color(0xFFD97706), 'target': const DoctorSchedulePage()},
      {'icon': Icons.folder_shared_rounded, 'label': 'Hồ sơ BN', 'color': const Color(0xFF0EA5E9), 'target': const DoctorPatientRecordsPage()},
      {'icon': Icons.medication_rounded, 'label': 'Kê đơn', 'color': const Color(0xFF8B5CF6), 'target': const DoctorPrescriptionBuilderPage()},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1),
      itemCount: tools.length,
      itemBuilder: (context, i) {
        final t = tools[i];
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => t['target'] as Widget)),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (t['color'] as Color).withOpacity(0.12), shape: BoxShape.circle), child: Icon(t['icon'] as IconData, color: t['color'] as Color, size: 20)),
                const SizedBox(height: 8),
                Text(t['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF15233D))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF8A95AC)),
          SizedBox(width: 12),
          Text('Hiện chưa có lịch khám bổ sung trong ngày', style: TextStyle(color: Color(0xFF8A95AC), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPerformanceSnapshot() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ĐÁNH GIÁ CHUNG', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)),
                  Text('9.8/10 Hài lòng', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
              Icon(Icons.auto_awesome_rounded, color: Colors.yellow[700]),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(value: 0.98, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!), minHeight: 4),
        ],
      ),
    );
  }
}
