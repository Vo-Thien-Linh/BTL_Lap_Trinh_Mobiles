import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../config/service_locator.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isCreatingDemoData = false;
  bool _isLoggingOut = false;

  final LogoutUsecase _logoutUsecase = getIt<LogoutUsecase>();

  Future<void> _createDemoAppointment() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Ban can dang nhap de tao du lieu mau.');
      return;
    }

    setState(() {
      _isCreatingDemoData = true;
    });

    try {
      final db = FirebaseFirestore.instance;

      await db.collection('Departments').doc('tim_mach').set({
        'name': 'Tim mach',
        'description': 'Khoa chuyen khoa tim mach',
        'location': 'Tang 2 - Phong 201',
        'phone': '0123456789',
      }, SetOptions(merge: true));

      await db.collection('Doctors').doc('dr_nguyen_van_b').set({
        'name': 'Bac si Nguyen Van B',
        'specialization': 'Tim mach',
        'departmentId': 'tim_mach',
        'yearsOfExperience': 8,
        'consultationFee': 500000,
        'isActive': true,
        'licenseNumber': 'BS12345',
      }, SetOptions(merge: true));

      await db
          .collection('DoctorSchedules')
          .doc('dr_b_2026_04_05_morning')
          .set({
            'doctorId': 'dr_nguyen_van_b',
            'departmentId': 'tim_mach',
            'scheduleDate': Timestamp.fromDate(DateTime(2026, 4, 5)),
            'shift': 'morning',
            'availableSlots': 5,
            'isActive': true,
          }, SetOptions(merge: true));

      await db.collection('Appointments').add({
        'patientId': user.uid,
        'doctorId': 'dr_nguyen_van_b',
        'departmentId': 'tim_mach',
        'appointmentDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 2)),
        ),
        'shift': 'morning',
        'symptoms': 'Dau nguc, kho tho nhe',
        'status': 'pending',
        'doctorName': 'Bac si Nguyen Van B',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showMessage('Da tao du lieu mau thanh cong.', isError: false);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showMessage(error.message ?? 'Khong the tao du lieu mau.');
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingDemoData = false;
        });
      }
    }
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
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _logoutUsecase();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoggingOut = false;
      });
      _showMessage('Khong the dang xuat. Vui long thu lai.');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoggingOut = false;
    });

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
              _buildFirestoreDemo(),
              const SizedBox(height: 26),
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHÀO MỪNG TRỞ LẠI,',
                style: TextStyle(
                  color: Color(0xFF222638),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Alexander',
                style: TextStyle(
                  color: Color(0xFF0A3DA8),
                  fontSize: 38 / 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
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
          const Text(
            'Dr. Sarah Jenkins',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42 / 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bác sĩ Tim mạch Cao cấp • Trung\ntâm Tim mạch & Mạch máu',
            style: TextStyle(
              color: Colors.white.withOpacity(0.73),
              fontSize: 34 / 2.35,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF8AF7F2),
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                '24 Tháng 10, 2023',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 26),
              Icon(
                Icons.access_time_filled_rounded,
                color: Color(0xFF8AF7F2),
                size: 21,
              ),
              SizedBox(width: 10),
              Text(
                '09:30 AM',
                style: TextStyle(
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
      ),
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
    const categories = [
      _CategoryItem(
        'Tim mạch',
        Icons.favorite,
        Color(0xFFF5EAEA),
        Color(0xFFE53935),
      ),
      _CategoryItem(
        'Nội tiết',
        Icons.biotech_rounded,
        Color(0xFFE8F6EC),
        Color(0xFF10A94E),
      ),
      _CategoryItem(
        'Nhi khoa',
        Icons.sentiment_satisfied_rounded,
        Color(0xFFEAF0F8),
        Color(0xFF3A6EE8),
      ),
    ];

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
            const Text(
              'Xem tất cả',
              style: TextStyle(
                color: Color(0xFF0A3DA8),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(categories.length, (index) {
            final item = categories[index];
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index == categories.length - 1 ? 0 : 12,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEFF6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: item.bg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(item.icon, color: item.fg, size: 32),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Color(0xFF222739),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFirestoreDemo() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Firestore Demo',
            style: TextStyle(
              color: Color(0xFF131826),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bam de tao 1 lich hen mau va xem du lieu vua tao.',
            style: TextStyle(
              color: Color(0xFF4A5164),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCreatingDemoData ? null : _createDemoAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E47B5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isCreatingDemoData
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(
                _isCreatingDemoData
                    ? 'Dang tao du lieu...'
                    : 'Them du lieu mau',
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (uid == null)
            const Text(
              'Chua dang nhap, khong the doc danh sach lich hen.',
              style: TextStyle(color: Color(0xFF7E869A), fontSize: 12),
            )
          else
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Appointments')
                  .where('patientId', isEqualTo: uid)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  );
                }

                if (snapshot.hasError) {
                  return const Text(
                    'Khong tai duoc lich hen.',
                    style: TextStyle(color: Color(0xFFB3261E), fontSize: 12),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Text(
                    'Chua co du lieu lich hen. Bam nut ben tren de tao mau.',
                    style: TextStyle(color: Color(0xFF6C7387), fontSize: 12),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final doctorName =
                        (data['doctorName'] ?? 'Bac si') as String;
                    final status = (data['status'] ?? 'pending') as String;
                    final appointmentDate = data['appointmentDate'];

                    String dateText = 'Chua co ngay';
                    if (appointmentDate is Timestamp) {
                      final dt = appointmentDate.toDate();
                      dateText =
                          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                    }

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_available_rounded,
                            color: Color(0xFF0E47B5),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$doctorName - $dateText',
                              style: const TextStyle(
                                color: Color(0xFF232838),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            status,
                            style: const TextStyle(
                              color: Color(0xFF0A3DA8),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
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
            const Text(
              'Xem tất cả',
              style: TextStyle(
                color: Color(0xFF0A3DA8),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _DoctorCard(
                name: 'Dr. Elena Rodriguez',
                spec: 'Bác sĩ Thần kinh',
                rating: '4.9',
                experience: '12 năm kinh nghiệm',
                imageUrl:
                    'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=300',
              ),
              SizedBox(width: 14),
              _DoctorCard(
                name: 'Dr. Aidan Walker',
                spec: 'Bác sĩ Tổng quát',
                rating: '4.8',
                experience: '9 năm kinh nghiệm',
                imageUrl:
                    'https://images.unsplash.com/photo-1612349316228-5942a9b489c2?w=300',
              ),
            ],
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

class _CategoryItem {
  const _CategoryItem(this.label, this.icon, this.bg, this.fg);

  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
}
