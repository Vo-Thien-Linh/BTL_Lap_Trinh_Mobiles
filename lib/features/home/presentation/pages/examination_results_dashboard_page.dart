import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:baitaplon/features/appointment/data/models/appointment_models.dart';
import 'package:baitaplon/app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class ExaminationResultsDashboardPage extends StatefulWidget {
  const ExaminationResultsDashboardPage({super.key});

  @override
  State<ExaminationResultsDashboardPage> createState() =>
      _ExaminationResultsDashboardPageState();
}

class _ExaminationResultsDashboardPageState
    extends State<ExaminationResultsDashboardPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    // Simulating fetching latest results
    await Future.delayed(Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ÄÃ£ cáº­p nháº­t dá»¯ liá»‡u sá»©c khá»e má»›i nháº¥t',
          ),
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
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientIdentityCard(uid),
                  SizedBox(height: 28),
                  _buildVitalsSummarySection(uid),
                  SizedBox(height: 28),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'KHO Há»’ SÆ  Y Táº¾',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildCategoryGrid(context),
                  SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Káº¾T QUáº¢ Gáº¦N ÄÃ‚Y',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.examinationHistory,
                          arguments: 'completed',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Táº¥t cáº£',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _buildRecentResultsList(uid),
                  SizedBox(height: 48),
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
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'TRUNG TÃ‚M Káº¾T QUáº¢',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : IconButton(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 22),
              ),
        IconButton(
          onPressed: () => _showHelpDialog(context),
          icon: const Icon(Icons.help_outline_rounded, size: 20),
          tooltip: 'HÆ°á»›ng dáº«n sá»­ dá»¥ng',
        ),
      ],
    );
  }

  Widget _buildPatientIdentityCard(String? uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: uid == null
          ? null
          : FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        String name = 'Vui lÃ²ng Ä‘Äƒng nháº­p';
        String id = 'N/A';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['fullName'] ?? 'NgÆ°á»i dÃ¹ng';
          id = _shortId(uid ?? '');
        }

        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
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
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'MÃƒ BN: $id',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  const Text(
                    'NHÃ“M MÃU',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'O+',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
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

  Widget _buildVitalsSummarySection(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: uid == null
          ? null
          : FirebaseFirestore.instance
                .collection('Appointments')
                .where('patientId', isEqualTo: uid)
                .where('status', isEqualTo: 'completed')
                .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyVitalsPlaceholder();
        }

        // Sort in memory to avoid index requirement
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final da = _readDate(
            (a.data() as Map<String, dynamic>)['appointmentDate'],
          );
          final db = _readDate(
            (b.data() as Map<String, dynamic>)['appointmentDate'],
          );
          return db.compareTo(da);
        });

        final data = docs.first.data() as Map<String, dynamic>;
        final vitals = _readMap(data['vitals']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'CHá»ˆ Sá» Sá»¨C KHá»ŽE Má»šI NHáº¤T',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildVitalCard(
                    'Huyáº¿t Ã¡p',
                    _firstVitalText(vitals, const [
                      'bloodPressure',
                      'pressure',
                    ], fallback: '--/--'),
                    'mmHg',
                    AppColors.error,
                    Icons.speed_rounded,
                  ),
                  SizedBox(width: 16),
                  _buildVitalCard(
                    'Nhá»‹p tim',
                    _firstVitalText(vitals, const [
                      'heartRate',
                      'pulse',
                    ], fallback: '--'),
                    'bpm',
                    Color(0xFFF97316),
                    Icons.favorite_rounded,
                  ),
                  SizedBox(width: 16),
                  _buildVitalCard(
                    'BMI',
                    _firstVitalText(vitals, const ['bmi'], fallback: '--'),
                    'Normal',
                    AppColors.success,
                    Icons.fitness_center_rounded,
                  ),
                  SizedBox(width: 16),
                  _buildVitalCard(
                    'Nhiá»‡t Ä‘á»™',
                    _firstVitalText(vitals, const [
                      'temperature',
                      'temp',
                    ], fallback: '--'),
                    'Â°C',
                    AppColors.primary,
                    Icons.thermostat_rounded,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVitalCard(
    String label,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBody.withOpacity(0.02),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textBody,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBody,
                ),
              ),
              Spacer(),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = [
      {
        'label': 'Sá»• XÃ©t Nghiá»‡m',
        'icon': Icons.science_rounded,
        'color': AppColors.primary,
      },
      {
        'label': 'ÄÆ¡n Thuá»‘c',
        'icon': Icons.medication_rounded,
        'color': AppColors.success,
      },
      {
        'label': 'Cháº©n ÄoÃ¡n HA',
        'icon': Icons.image_search_rounded,
        'color': Color(0xFF6366F1),
      },
      {
        'label': 'Lá»‹ch Sá»­ KhÃ¡m',
        'icon': Icons.history_edu_rounded,
        'color': AppColors.warning,
      },
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
            if (cat['label'] == 'Lá»‹ch Sá»­ KhÃ¡m') {
              Navigator.pushNamed(
                context,
                AppRoutes.examinationHistory,
                arguments: 'completed',
              );
            } else {
              Navigator.pushNamed(
                context,
                AppRoutes.medicalVaultCategory,
                arguments: cat['label'] as String,
              );
            }
          },
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textBody.withOpacity(0.02),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(cat['icon'] as IconData, color: color, size: 24),
                ),
                Text(
                  cat['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textBody,
                  ),
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
      stream: uid == null
          ? null
          : FirebaseFirestore.instance
                .collection('Appointments')
                .where('patientId', isEqualTo: uid)
                .where('status', isEqualTo: 'completed')
                .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return SizedBox.shrink();
        if (snapshot.connectionState == ConnectionState.waiting)
          return SizedBox(height: 100);
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'ChÆ°a cÃ³ káº¿t quáº£ khÃ¡m gáº§n Ä‘Ã¢y',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        // Sort in memory to avoid index requirement
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final da = _readDate(
            (a.data() as Map<String, dynamic>)['appointmentDate'],
          );
          final db = _readDate(
            (b.data() as Map<String, dynamic>)['appointmentDate'],
          );
          return db.compareTo(da);
        });

        final items = docs
            .take(3)
            .map((d) => HospitalAppointmentModel.fromFirestore(d))
            .toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textBody.withOpacity(0.02),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.examinationDetail,
                  arguments: item,
                ),
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.assignment_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.doctorName,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.textBody,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            item.diagnosis ?? "ÄÃ£ cÃ³ bá»‡nh Ã¡n chi tiáº¿t",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.border),
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
              // Header vá»›i Background Gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TRUNG TÃ‚M Káº¾T QUáº¢',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHelpItem(
                      Icons.folder_shared_rounded,
                      'Kho Há»“ SÆ¡ Y Táº¿',
                      'LÆ°u trá»¯ táº¥t cáº£ káº¿t quáº£ khÃ¡m, Ä‘Æ¡n thuá»‘c, xÃ©t nghiá»‡m mÃ¡u vÃ  hÃ¬nh áº£nh X-Quang/SiÃªu Ã¢m cá»§a báº¡n.',
                    ),
                    _buildHelpItem(
                      Icons.sync_rounded,
                      'Cáº­p Nháº­t Tá»± Äá»™ng',
                      'Dá»¯ liá»‡u sáº½ Ä‘Æ°á»£c cáº­p nháº­t tá»± Ä‘á»™ng sau ca khÃ¡m tá»« 30-60 phÃºt. Báº¡n cÃ³ thá»ƒ nháº¥n nÃºt lÃ m má»›i á»Ÿ gÃ³c trÃªn.',
                    ),
                    _buildHelpItem(
                      Icons.security_rounded,
                      'Báº£o Máº­t ThÃ´ng Tin',
                      'Táº¥t cáº£ dá»¯ liá»‡u y táº¿ Ä‘á»u Ä‘Æ°á»£c mÃ£ hÃ³a vÃ  chá»‰ cÃ³ báº¡n cÃ¹ng bÃ¡c sÄ© Ä‘iá»u trá»‹ má»›i cÃ³ quyá»n truy cáº­p.',
                    ),
                    _buildHelpItem(
                      Icons.history_rounded,
                      'Lá»‹ch Sá»­ Trá»n Äá»i',
                      'Há»‡ thá»‘ng lÆ°u trá»¯ lá»‹ch sá»­ sá»©c khá»e giÃºp bÃ¡c sÄ© theo dÃµi tiáº¿n trÃ¬nh vÃ  Ä‘Æ°a ra cháº©n Ä‘oÃ¡n chÃ­nh xÃ¡c hÆ¡n.',
                    ),

                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ÄÃƒ HIá»‚U',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
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
      padding: EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textBody,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    height: 1.5,
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

  DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime(1900);
  }

  Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const {};
  }

  String _firstVitalText(
    Map<String, dynamic> vitals,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = vitals[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  String _shortId(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return 'NONE';
    final end = cleaned.length < 8 ? cleaned.length : 8;
    return cleaned.substring(0, end).toUpperCase();
  }
}

class _EmptyVitalsPlaceholder extends StatelessWidget {
  _EmptyVitalsPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.monitor_heart_outlined,
              size: 40,
              color: AppColors.textHint,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'ChÆ°a cÃ³ chá»‰ sá»‘ sinh tá»“n',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textBody,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'CÃ¡c chá»‰ sá»‘ cá»§a báº¡n sáº½ Ä‘Æ°á»£c cáº­p nháº­t tá»± Ä‘á»™ng sau ca khÃ¡m Ä‘áº§u tiÃªn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
