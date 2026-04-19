import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:baitaplon/features/appointment/data/models/appointment_models.dart';
import 'package:baitaplon/app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class ExaminationResultsDashboardPage extends StatefulWidget {
  const ExaminationResultsDashboardPage({super.key});

  @override
  State<ExaminationResultsDashboardPage> createState() => _ExaminationResultsDashboardPageState();
}

class _ExaminationResultsDashboardPageState extends State<ExaminationResultsDashboardPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAndSeedData();
  }

  Future<void> _checkAndSeedData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('Appointments')
        .where('patientId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      await _autoSeedCompletedResult(uid);
    }
  }

  Future<void> _autoSeedCompletedResult(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now();
    final appId = 'MOCK-RESULT-${uid.substring(0, 5)}';

    batch.set(FirebaseFirestore.instance.collection('Appointments').doc(appId), {
      'patientId': uid,
      'patientName': 'Bệnh nhân Demo',
      'doctorName': 'BS. Nguyễn Văn A',
      'departmentName': 'Khoa Nội tổng quát',
      'appointmentDate': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      'status': 'completed',
      'appointmentTime': '08:30 AM',
      'symptoms': 'Đau đầu nhẹ, chóng mặt kéo dài 3 ngày.',
      'diagnosis': 'Suy nhược cơ thể nhẹ do làm việc quá sức. Cần điều chỉnh chế độ sinh hoạt.',
      'physicalExam': 'Niêm mạc hồng, tim đều, phổi trong, không rale. Huyết áp ổn định.',
      'treatment': 'Nghỉ ngơi 3 ngày, ăn uống đầy đủ dưỡng chất, hạn chế sử dụng thiết bị điện tử sau 10 giờ tối.',
      'vitals': {
        'pressure': '120/80',
        'pulse': '72',
        'temp': '36.5',
        'bmi': '22.1',
      },
      'prescription': [
        {'name': 'Panadol Extra', 'dosage': 'Sáng 1 v, Chiều 1 v (Sau ăn)'},
        {'name': 'Vitamin C 500mg', 'dosage': 'Sáng 1 v (Sau ăn)'},
        {'name': 'Magnesium B6', 'dosage': 'Tối 1 v (Trước khi đi ngủ)'},
      ],
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
    });

    await batch.commit();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    // Simulating fetching latest results
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật dữ liệu sức khỏe mới nhất'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildPatientIdentityCard(uid),
                   const SizedBox(height: 28),
                   _buildVitalsSummarySection(uid),
                   const SizedBox(height: 28),
                   Row(
                     children: [
                       Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                       const SizedBox(width: 8),
                       const Text(
                        'KHO HỒ SƠ Y TẾ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.0),
                       ),
                     ],
                   ),
                   const SizedBox(height: 16),
                   _buildCategoryGrid(context),
                   const SizedBox(height: 28),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          const Text(
                            'KẾT QUẢ GẦN ĐÂY',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.0),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.examinationHistory, arguments: 'Hoàn thành'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        child: const Row(
                          children: [
                            Text('Tất cả', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            Icon(Icons.chevron_right_rounded, size: 18),
                          ],
                        ),
                      ),
                    ],
                   ),
                   _buildRecentResultsList(uid),
                   const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'TRUNG TÂM KẾT QUẢ',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF3B82F6)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        _isLoading 
          ? const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))))
          : IconButton(
              onPressed: _handleRefresh, 
              icon: const Icon(Icons.refresh_rounded, size: 22)
            ),
        IconButton(
          onPressed: () => _showHelpDialog(context), 
          icon: const Icon(Icons.help_outline_rounded, size: 20),
          tooltip: 'Hướng dẫn sử dụng',
        ),
      ],
    );
  }

  Widget _buildPatientIdentityCard(String? uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: uid == null ? null : FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        String name = 'Vui lòng đăng nhập';
        String id = 'N/A';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['fullName'] ?? 'Người dùng';
          id = uid?.substring(0, 8).toUpperCase() ?? 'NONE';
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'MÃ BN: $id',
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  const Text('NHÓM MÁU', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                      'O+',
                      style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w900),
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

  Widget _buildVitalsSummarySection(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: uid == null ? null : FirebaseFirestore.instance
          .collection('Appointments')
          .where('patientId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink(); 
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const _EmptyVitalsPlaceholder();
        }

        // Sort in memory to avoid index requirement
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final da = (a.data() as Map<String, dynamic>)['appointmentDate'] as Timestamp;
          final db = (b.data() as Map<String, dynamic>)['appointmentDate'] as Timestamp;
          return db.compareTo(da);
        });

        final data = docs.first.data() as Map<String, dynamic>;
        final vitals = data['vitals'] as Map<String, dynamic>? ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                const Text(
                  'CHỈ SỐ SỨC KHỎE MỚI NHẤT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.0),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildVitalCard('Huyết áp', vitals['pressure'] ?? '120/80', 'mmHg', AppColors.error, Icons.speed_rounded),
                  const SizedBox(width: 16),
                  _buildVitalCard('Nhịp tim', vitals['pulse'] ?? '75', 'bpm', const Color(0xFFF97316), Icons.favorite_rounded),
                  const SizedBox(width: 16),
                  _buildVitalCard('BMI', vitals['bmi'] ?? '22.4', 'Normal', AppColors.success, Icons.fitness_center_rounded),
                  const SizedBox(width: 16),
                  _buildVitalCard('Nhiệt độ', vitals['temp'] ?? '36.6', '°C', AppColors.primary, Icons.thermostat_rounded),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVitalCard(String label, String value, String unit, Color color, IconData icon) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.textBody.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textBody),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textBody)),
              const Spacer(),
              Text(unit, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = [
      {'label': 'Sổ Xét Nghiệm', 'icon': Icons.science_rounded, 'color': AppColors.primary},
      {'label': 'Đơn Thuốc', 'icon': Icons.medication_rounded, 'color': AppColors.success},
      {'label': 'Chẩn Đoán HA', 'icon': Icons.image_search_rounded, 'color': const Color(0xFF6366F1)},
      {'label': 'Lịch Sử Khám', 'icon': Icons.history_edu_rounded, 'color': AppColors.warning},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final color = cat['color'] as Color;
        return InkWell(
          onTap: () {
            if (cat['label'] == 'Lịch Sử Khám') {
              Navigator.pushNamed(context, AppRoutes.examinationHistory, arguments: 'Hoàn thành');
            } else {
              Navigator.pushNamed(context, AppRoutes.medicalVaultCategory, arguments: cat['label'] as String);
            }
          },
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: AppColors.textBody.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(cat['icon'] as IconData, color: color, size: 24),
                ),
                Text(
                  cat['label'] as String,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textBody),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentResultsList(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: uid == null ? null : FirebaseFirestore.instance
          .collection('Appointments')
          .where('patientId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 100);
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Chưa có kết quả khám gần đây',
                style: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }

        // Sort in memory to avoid index requirement
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final da = (a.data() as Map<String, dynamic>)['appointmentDate'] as Timestamp;
          final db = (b.data() as Map<String, dynamic>)['appointmentDate'] as Timestamp;
          return db.compareTo(da);
        });

        final items = docs.take(3).map((d) => HospitalAppointmentModel.fromFirestore(d)).toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.textBody.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.examinationDetail, arguments: item),
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.assignment_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.doctorName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textBody)),
                          const SizedBox(height: 2),
                          Text(
                            item.diagnosis ?? "Đã có bệnh án chi tiết",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.border),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header với Background Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF3B82F6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text('TRUNG TÂM KẾT QUẢ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHelpItem(Icons.folder_shared_rounded, 'Kho Hồ Sơ Y Tế', 'Lưu trữ tất cả kết quả khám, đơn thuốc, xét nghiệm máu và hình ảnh X-Quang/Siêu âm của bạn.'),
                    _buildHelpItem(Icons.sync_rounded, 'Cập Nhật Tự Động', 'Dữ liệu sẽ được cập nhật tự động sau ca khám từ 30-60 phút. Bạn có thể nhấn nút làm mới ở góc trên.'),
                    _buildHelpItem(Icons.security_rounded, 'Bảo Mật Thông Tin', 'Tất cả dữ liệu y tế đều được mã hóa và chỉ có bạn cùng bác sĩ điều trị mới có quyền truy cập.'),
                    _buildHelpItem(Icons.history_rounded, 'Lịch Sử Trọn Đời', 'Hệ thống lưu trữ lịch sử sức khỏe giúp bác sĩ theo dõi tiến trình và đưa ra chẩn đoán chính xác hơn.'),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('ĐÃ HIỂU', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textBody)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVitalsPlaceholder extends StatelessWidget {
  const _EmptyVitalsPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
            child: const Icon(Icons.monitor_heart_outlined, size: 40, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có chỉ số sinh tồn',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textBody),
          ),
          const SizedBox(height: 8),
          const Text(
            'Các chỉ số của bạn sẽ được cập nhật tự động sau ca khám đầu tiên.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
