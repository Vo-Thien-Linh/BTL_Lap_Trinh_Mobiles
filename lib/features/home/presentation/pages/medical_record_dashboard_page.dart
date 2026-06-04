import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/user_model.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class MedicalRecordDashboardPage extends StatefulWidget {
  const MedicalRecordDashboardPage({super.key});

  @override
  State<MedicalRecordDashboardPage> createState() =>
      _MedicalRecordDashboardPageState();
}

class _MedicalRecordDashboardPageState
    extends State<MedicalRecordDashboardPage> {
  Stream<DocumentSnapshot> _getUserStream(String uid) async* {
    final lowerRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final upperRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final lowerSnap = await lowerRef.get();
    if (lowerSnap.exists) {
      yield* lowerRef.snapshots();
    } else {
      yield* upperRef.snapshots();
    }
  }

  Stream<QuerySnapshot> _getLatestAppointmentStream(String uid) {
    return FirebaseFirestore.instance
        .collection('Appointments')
        .where('patientId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: uid == null ? null : _getUserStream(uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          UserModel user = userSnapshot.hasData && userSnapshot.data!.exists
              ? UserModel.fromDocument(userSnapshot.data!)
              : UserModel.empty();

          return StreamBuilder<QuerySnapshot>(
            stream: uid == null ? null : _getLatestAppointmentStream(uid),
            builder: (context, apptSnapshot) {
              Map<String, dynamic> vitals = {};
              if (apptSnapshot.hasData && apptSnapshot.data!.docs.isNotEmpty) {
                final docs = apptSnapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final da =
                      (a.data() as Map<String, dynamic>)['appointmentDate']
                          as Timestamp;
                  final db =
                      (b.data() as Map<String, dynamic>)['appointmentDate']
                          as Timestamp;
                  return db.compareTo(da);
                });
                final latestApptData =
                    docs.first.data() as Map<String, dynamic>;
                vitals =
                    latestApptData['vitals'] as Map<String, dynamic>? ?? {};
              }

              return CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context, user),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEmergencyBanner(context, user),
                          const SizedBox(height: 24),
                          _buildSectionTitle('CHỈ SỐ SINH HIỆU MỚI NHẤT'),
                          const SizedBox(height: 16),
                          _buildVitalsGrid(user, vitals),
                          const SizedBox(height: 32),
                          _buildSectionTitle('THÔNG TIN LÂM SÀNG'),
                          const SizedBox(height: 16),
                          _buildClinicalSection(user),
                          const SizedBox(height: 32),
                          _buildSectionTitle('KHO DỮ LIỆU SỨC KHỎE'),
                          const SizedBox(height: 16),
                          _buildVaultNavigation(context),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, UserModel user) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 220,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đang làm mới dữ liệu lâm sàng...'),
                duration: Duration(seconds: 1),
                backgroundColor: Color(0xFF3B82F6),
              ),
            );
          },
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Làm mới',
        ),
        IconButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.medicalEmergencyId),
          icon: const Icon(Icons.qr_code_scanner_rounded),
          tooltip: 'Mã QR Y tế',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Light medical patterns
            Opacity(
              opacity: 0.1,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://www.transparenttextures.com/patterns/white-diamond.png',
                    ),
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 4,
                        ),
                        image: DecorationImage(
                          image: NetworkImage(
                            user.avatarUrl ??
                                'https://ui-avatars.com/api/?name=${user.fullName}&background=random',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName == ''
                                ? 'Người Dùng'
                                : user.fullName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'BỆNH NHÂN ĐÃ XÁC THỰC',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildBioTag(
                                'NHÓM MÁU: ${user.bloodType ?? "--"}',
                              ),
                              const SizedBox(width: 8),
                              _buildBioTag(
                                'TUỔI: ${_calculateAge(user.dateOfBirth)}',
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildBioTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner(BuildContext context, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emergency_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THÔNG TIN KHẨN CẤP',
                  style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dị ứng: ${user.allergies?.join(", ") ?? "Không có"}',
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.medicalEmergencyId),
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF991B1B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsGrid(UserModel user, Map<String, dynamic> vitals) {
    final heartRate = vitals['heartRate'] ?? vitals['pulse'];
    final bloodPressure = vitals['bloodPressure'] ?? vitals['pressure'];
    final spO2 = vitals['spO2'];

    final hasHeartRate =
        heartRate != null &&
        heartRate.toString().trim().isNotEmpty &&
        heartRate.toString() != '--';
    final hasBloodPressure =
        bloodPressure != null &&
        bloodPressure.toString().trim().isNotEmpty &&
        bloodPressure.toString() != '--/--';
    final hasSpO2 =
        spO2 != null &&
        spO2.toString().trim().isNotEmpty &&
        spO2.toString() != '--';
    final hasWeight = user.weight != null && user.weight! > 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.35,
      children: [
        _buildVitalCard(
          'Nhịp tim',
          hasHeartRate ? heartRate.toString() : '--',
          'bpm',
          Icons.favorite_rounded,
          Colors.red,
          hasHeartRate ? 'up' : 'even',
        ),
        _buildVitalCard(
          'Huyết áp',
          hasBloodPressure ? bloodPressure.toString() : '--/--',
          'mmHg',
          Icons.bloodtype_rounded,
          Colors.blue,
          hasBloodPressure ? 'even' : 'even',
        ),
        _buildVitalCard(
          'SpO2',
          hasSpO2 ? spO2.toString() : '--',
          '%',
          Icons.air_rounded,
          Colors.cyan,
          hasSpO2 ? 'even' : 'even',
        ),
        _buildVitalCard(
          'Cân nặng',
          hasWeight
              ? '${user.weight!.toInt() == user.weight ? user.weight!.toInt() : user.weight}'
              : '--',
          'kg',
          Icons.monitor_weight_rounded,
          Colors.orange,
          hasWeight ? 'down' : 'even',
        ),
      ],
    );
  }

  Widget _buildVitalCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              _buildTrendIndicator(trend),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(String trend) {
    if (trend == 'up')
      return const Icon(
        Icons.trending_up_rounded,
        color: Colors.redAccent,
        size: 16,
      );
    if (trend == 'down')
      return const Icon(
        Icons.trending_down_rounded,
        color: AppColors.success,
        size: 16,
      );
    return const Icon(
      Icons.trending_flat_rounded,
      color: AppColors.textHint,
      size: 16,
    );
  }

  Widget _buildClinicalSection(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClinicalRow(
            'Bệnh mãn tính',
            user.chronicConditions?.join(", ") ?? "Không có dữ liệu",
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.border),
          ),
          _buildClinicalRow(
            'Bảo hiểm y tế',
            user.healthInsuranceNumber ?? "--- --- --- ---",
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.border),
          ),
          _buildClinicalRow(
            'Địa chỉ thường trú',
            user.address ?? "Chưa cập nhật",
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textBody,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildVaultNavigation(BuildContext context) {
    return Column(
      children: [
        _buildVaultTile(
          context,
          'Sổ Xét Nghiệm',
          'Tổng hợp kết quả xét nghiệm máu, sinh hóa...',
          Icons.biotech_rounded,
          const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 12),
        _buildVaultTile(
          context,
          'Đơn Thuốc',
          'Lịch sử kê đơn và hướng dẫn sử dụng thuốc',
          Icons.medication_rounded,
          const Color(0xFF10B981),
        ),
        const SizedBox(height: 12),
        _buildVaultTile(
          context,
          'Chẩn Đoán HA',
          'Kho ảnh X-Quang, Siêu âm, MRI, CT Scan',
          Icons.camera_rounded,
          const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 12),
        _buildVaultTile(
          context,
          'Lịch Sử Điều Trị',
          'Toàn bộ quá trình thăm khám tại bệnh viện',
          Icons.history_rounded,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildVaultTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        if (title == 'Lịch Sử Điều Trị') {
          Navigator.pushNamed(
            context,
            AppRoutes.examinationHistory,
            arguments: 'completed',
          );
        } else {
          Navigator.pushNamed(
            context,
            AppRoutes.medicalVaultCategory,
            arguments: title,
          );
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textBody,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textHint,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  String _calculateAge(String? dob) {
    if (dob == null) return "N/A";
    try {
      final birthDate = DateFormat('dd/MM/yyyy').parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return dob;
    }
  }
}
