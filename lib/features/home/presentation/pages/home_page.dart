import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../config/service_locator.dart';
import '../../../appointment/data/models/appointment_models.dart';
import '../../../appointment/domain/entities/appointment_entities.dart';
import '../../../appointment/domain/usecases/appointment_usecases.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LogoutUsecase _logoutUsecase = getIt<LogoutUsecase>();
  late final Future<String> _userNameFuture;
  late final Future<List<DepartmentEntity>> _departmentsFuture;
  late final Future<List<DoctorEntity>> _featuredDoctorsFuture;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _userNameFuture = _loadUserName();
    _departmentsFuture = _loadDepartments();
    _featuredDoctorsFuture = _loadFeaturedDoctors();
  }

  Future<String> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Khách';

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      final fullName = (data?['fullName'] as String?)?.trim();
      if (fullName != null && fullName.isNotEmpty) return fullName;

      final username = (data?['username'] as String?)?.trim();
      if (username != null && username.isNotEmpty) return username;
    } catch (_) {
      // fallback below
    }

    return user.email?.split('@').first ?? 'Người dùng';
  }

  Future<List<DepartmentEntity>> _loadDepartments() async {
    final departments = await getIt<GetDepartmentsUsecase>()();
    return departments.take(4).toList();
  }

  Future<List<DoctorEntity>> _loadFeaturedDoctors() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Doctors')
        .where('isActive', isEqualTo: true)
        .limit(4)
        .get();

    return snapshot.docs.map(DoctorModel.fromFirestore).toList();
  }

  _DepartmentVisual _departmentVisual(int index) {
    switch (index % 6) {
      case 0:
        return const _DepartmentVisual(
          icon: Icons.favorite_rounded,
          colors: [Color(0xFFEC5D5D), Color(0xFFB91C1C)],
        );
      case 1:
        return const _DepartmentVisual(
          icon: Icons.biotech_rounded,
          colors: [Color(0xFF2DD4BF), Color(0xFF0F766E)],
        );
      case 2:
        return const _DepartmentVisual(
          icon: Icons.child_care_rounded,
          colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
        );
      case 3:
        return const _DepartmentVisual(
          icon: Icons.medical_services_rounded,
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
      case 4:
        return const _DepartmentVisual(
          icon: Icons.visibility_rounded,
          colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
        );
      default:
        return const _DepartmentVisual(
          icon: Icons.healing_rounded,
          colors: [Color(0xFF34D399), Color(0xFF059669)],
        );
    }
  }

  void _showDepartmentsSheet(List<DepartmentEntity> departments) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DCE6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Text(
                  'Tất cả chuyên khoa',
                  style: TextStyle(
                    color: Color(0xFF131826),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Chọn chuyên khoa để xem bác sĩ phù hợp.',
                  style: TextStyle(
                    color: Color(0xFF5C6477),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: departments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final department = departments[index];
                    final visual = _departmentVisual(index);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE8EBF4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: visual.colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: visual.colors.first.withOpacity(0.22),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              visual.icon,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  department.name,
                                  style: const TextStyle(
                                    color: Color(0xFF131826),
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  department.location.isNotEmpty
                                      ? department.location
                                      : department.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF5C6477),
                                    fontSize: 12.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF8B92A6),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDoctorsSheet(List<DoctorEntity> doctors) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DCE6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Text(
                  'Bác sĩ nổi bật',
                  style: TextStyle(
                    color: Color(0xFF131826),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Danh sách bác sĩ đang hoạt động trong hệ thống.',
                  style: TextStyle(
                    color: Color(0xFF5C6477),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: doctors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE8EBF4)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: doctor.imageUrl == null
                                ? null
                                : NetworkImage(doctor.imageUrl!),
                            backgroundColor: const Color(0xFFE4ECFF),
                            child: doctor.imageUrl == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF0A3DA8),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  style: const TextStyle(
                                    color: Color(0xFF131826),
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor.departmentName.isNotEmpty
                                      ? doctor.departmentName
                                      : doctor.specialization,
                                  style: const TextStyle(
                                    color: Color(0xFF5C6477),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${doctor.yearsOfExperience} năm',
                            style: const TextStyle(
                              color: Color(0xFF0A3DA8),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFB3261E)
            : const Color(0xFF2E7D32),
      ),
    );
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);

    try {
      await _logoutUsecase();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      _showMessage('Khong the dang xuat. Vui long thu lai.');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoggingOut = false);

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 22),
              _buildSearch(),
              const SizedBox(height: 22),
              _buildUpcomingCard(),
              const SizedBox(height: 22),
              _buildActionGrid(),
              const SizedBox(height: 22),
              _buildCategorySection(),
              const SizedBox(height: 26),
              _buildDoctorSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF0E8B8E),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFBEE6EA),
            child: const Icon(Icons.person, color: Color(0xFF1E3148), size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<String>(
            future: _userNameFuture,
            builder: (context, snapshot) {
              final userName = snapshot.data ?? '...';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHÀO MỪNG TRỞ LẠI,',
                    style: TextStyle(
                      color: Color(0xFF222638),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0A3DA8),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const Icon(
          Icons.notifications_none_rounded,
          color: Color(0xFF202637),
          size: 28,
        ),
        const SizedBox(width: 14),
        TextButton.icon(
          onPressed: _isLoggingOut ? null : _handleLogout,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFC62828),
            backgroundColor: const Color(0xFFFFEBEE),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: _isLoggingOut
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout_rounded, size: 18),
          label: Text(
            _isLoggingOut ? '...' : 'Dang xuat',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: Color(0xFF2F3447), size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tìm bác sĩ, chuyên khoa, dịch vụ',
              style: TextStyle(
                color: Color(0xFF656A79),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F49B8), Color(0xFF1F5CC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C57BE).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3A73D0),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 9, color: Color(0xFF7EF8F5)),
                SizedBox(width: 8),
                Text(
                  'LỊCH HẸN SẮP TỚI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 / 1.55,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseAuth.instance.currentUser?.uid == null
                ? null
                : FirebaseFirestore.instance
                      .collection('Appointments')
                      .where(
                        'patientId',
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                      )
                      .orderBy('appointmentDate', descending: true)
                      .limit(1)
                      .snapshots(),
            builder: (context, snapshot) {
              if (FirebaseAuth.instance.currentUser?.uid == null) {
                return _buildEmptyUpcomingCard();
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: LinearProgressIndicator(minHeight: 2),
                );
              }

              if (snapshot.hasError) {
                return _buildEmptyUpcomingCard(
                  message: 'Khong tai duoc lich hen.',
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return _buildEmptyUpcomingCard();
              }

              final data = docs.first.data();
              final doctorName = (data['doctorName'] ?? 'Bác sĩ') as String;
              final departmentName =
                  (data['departmentName'] ?? 'Chuyên khoa') as String;
              final appointmentDate = (data['appointmentDate'] as Timestamp?)
                  ?.toDate();
              final dateText = appointmentDate == null
                  ? 'Chưa có ngày'
                  : '${appointmentDate.day.toString().padLeft(2, '0')}/${appointmentDate.month.toString().padLeft(2, '0')}/${appointmentDate.year}';
              final timeSlot =
                  (data['timeSlot'] ?? data['shift'] ?? 'Đang cập nhật')
                      as String;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$departmentName • $dateText',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.73),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: Color(0xFF8AF7F2),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dateText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 26),
                      const Icon(
                        Icons.access_time_filled_rounded,
                        color: Color(0xFF8AF7F2),
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        timeSlot,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F8),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          color: Color(0xFF09349E),
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUpcomingCard({
    String message =
        'Hãy đặt lịch để hệ thống hiển thị lịch hẹn mới nhất của bạn.',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chưa có lịch hẹn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            color: Colors.white.withOpacity(0.73),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F8),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Center(
            child: Text(
              'Đặt lịch ngay',
              style: TextStyle(
                color: Color(0xFF09349E),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid() {
    const items = [
      _ActionItem(
        'Đặt lịch khám',
        Icons.add_circle_outline_rounded,
        Color(0xFFC9D0EE),
        Color(0xFF1348B3),
      ),
      _ActionItem(
        'Kết quả khám',
        Icons.science_outlined,
        Color(0xFF8CE8E5),
        Color(0xFF0B6361),
      ),
      _ActionItem(
        'Đơn thuốc',
        Icons.medication_outlined,
        Color(0xFFC9D0EE),
        Color(0xFF1348B3),
      ),
      _ActionItem(
        'Thanh toán',
        Icons.payments_outlined,
        Color(0xFFEEDFC8),
        Color(0xFFDB6B00),
      ),
      _ActionItem(
        'Hồ sơ bệnh án',
        Icons.folder_shared_outlined,
        Color(0xFFCBE0FF),
        Color(0xFF315ED2),
      ),
      _ActionItem(
        'Lịch sử khám',
        Icons.history_toggle_off_rounded,
        Color(0xFFD7DCE6),
        Color(0xFF1F2737),
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.86,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            if (item.label == 'Đặt lịch khám') {
              Navigator.pushNamed(context, AppRoutes.booking);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEDEFF6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: item.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.fg, size: 30),
                ),
                const SizedBox(height: 13),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF232838),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Chuyên khoa',
                style: TextStyle(
                  color: Color(0xFF131826),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final departments = await _departmentsFuture;
                if (!mounted || departments.isEmpty) return;
                _showDepartmentsSheet(departments);
              },
              child: const Text(
                'Xem thêm',
                style: TextStyle(
                  color: Color(0xFF0A3DA8),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 176,
          child: FutureBuilder<List<DepartmentEntity>>(
            future: _departmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Không tải được chuyên khoa.'));
              }

              final departments = snapshot.data ?? [];
              if (departments.isEmpty) {
                return const Center(
                  child: Text('Chưa có dữ liệu chuyên khoa.'),
                );
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: departments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final department = departments[index];
                  final visual = _departmentVisual(index);
                  return Container(
                    width: 148,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8EBF4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: visual.colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: visual.colors.first.withOpacity(0.22),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -8,
                                bottom: -10,
                                child: Icon(
                                  visual.icon,
                                  size: 40,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              Center(
                                child: Icon(
                                  visual.icon,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          department.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF222739),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          department.location.isNotEmpty
                              ? department.location
                              : department.description,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF5C6477),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Bác sĩ nổi bật',
                style: TextStyle(
                  color: Color(0xFF131826),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final doctors = await _featuredDoctorsFuture;
                if (!mounted || doctors.isEmpty) return;
                _showDoctorsSheet(doctors);
              },
              child: const Text(
                'Xem thêm',
                style: TextStyle(
                  color: Color(0xFF0A3DA8),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: FutureBuilder<List<DoctorEntity>>(
            future: _featuredDoctorsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Không tải được bác sĩ.'));
              }

              final doctors = snapshot.data ?? [];
              if (doctors.isEmpty) {
                return const Center(child: Text('Chưa có dữ liệu bác sĩ.'));
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: doctors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final doctor = doctors[index];
                  return _DoctorCard(
                    name: doctor.name,
                    spec: doctor.departmentName.isNotEmpty
                        ? doctor.departmentName
                        : doctor.specialization,
                    rating: '4.8',
                    experience: '${doctor.yearsOfExperience} năm kinh nghiệm',
                    imageUrl:
                        doctor.imageUrl ??
                        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=300',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    const labels = ['TRANG CHU', 'LICH HEN', 'THONG BAO', 'HO SO'];
    const icons = [
      Icons.home_rounded,
      Icons.calendar_today_rounded,
      Icons.notifications_rounded,
      Icons.person_rounded,
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = index == 0;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF0E47B5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      size: 24,
                      color: selected ? Colors.white : const Color(0xFF7B7F8D),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF6E7381),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem(this.label, this.icon, this.bg, this.fg);

  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
}

class _DepartmentVisual {
  const _DepartmentVisual({required this.icon, required this.colors});

  final IconData icon;
  final List<Color> colors;
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.name,
    required this.spec,
    required this.rating,
    required this.experience,
    required this.imageUrl,
  });

  final String name;
  final String spec;
  final String rating;
  final String experience;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 355,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F6),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 98,
                height: 98,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFF056968),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: Color(0xFF056968),
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFF131826),
                          fontWeight: FontWeight.w800,
                          fontSize: 17.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        spec,
                        style: const TextStyle(
                          color: Color(0xFF454B5C),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        experience,
                        style: const TextStyle(
                          color: Color(0xFF0A3DA8),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6EAF2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Hồ sơ',
                      style: TextStyle(
                        color: Color(0xFF0A3DA8),
                        fontWeight: FontWeight.w700,
                        fontSize: 14.1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E47B5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Đặt lịch',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
