import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../../shared/utils/firebase_data_seeder.dart';
import '../../../home/presentation/pages/examination_history_page.dart';

class ProfilePage extends StatefulWidget {
  final int initialTab;
  const ProfilePage({super.key, this.initialTab = 0});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  UserModel? _userModel;
  List<Map<String, dynamic>> _familyMembers = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load User Profile
        final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
        if (doc.exists) {
          _userModel = UserModel.fromDocument(doc);
        }

        // Load Family Members
        final familySnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('FamilyMembers')
            .get();
        
        _familyMembers = familySnapshot.docs.map((d) => d.data()).toList();
        
        setState(() {});
      }
    } catch (e) {
      debugPrint('Lỗi tải hồ sơ: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_userModel == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy thông tin hồ sơ.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildPremiumSliverAppBar(),
            SliverToBoxAdapter(child: _buildDigitalHealthPass(_userModel!)),
            SliverToBoxAdapter(child: _buildHealthVitalsGrid(_userModel!)),
            if (_familyMembers.isNotEmpty)
              SliverToBoxAdapter(child: _buildFamilyCircleSection()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                Container(
                  color: AppColors.background,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textHint,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 4,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'THÔNG TIN'),
                      Tab(text: 'HÀNH TRÌNH'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(_userModel!),
            const ExaminationHistoryPage(
              isSubPage: true,
              defaultFilter: 'Hoàn thành',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSliverAppBar() {
    return const SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      centerTitle: true,
      title: Text(
        'HỒ SƠ CÁ NHÂN',
        style: TextStyle(
          fontSize: 14, 
          fontWeight: FontWeight.w900, 
          color: Colors.white, 
          letterSpacing: 2.0
        ),
      ),
    );
  }

  Widget _buildDigitalHealthPass(UserModel user) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF334155), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
          image: DecorationImage(
            image: const NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'),
            opacity: 0.05,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DIGITAL HEALTH PASS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Icon(Icons.contactless_outlined, color: Colors.white.withOpacity(0.5), size: 20),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primaryLight, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundImage: user.avatarUrl != null 
                              ? NetworkImage(user.avatarUrl!) 
                              : null,
                          backgroundColor: AppColors.primaryLight,
                          child: user.avatarUrl == null ? Text(user.fullName[0]) : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Patient ID: ${user.uid.substring(0, 12).toUpperCase()}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMemberInfoChip('THÀNH VIÊN', 'PREMIUM'),
                      GestureDetector(
                        onTap: () => _showQRCodeDialog(user),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.qr_code_rounded, color: Colors.black, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberInfoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w800)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildHealthVitalsGrid(UserModel user) {
    double bmi = (user.weight ?? 0) / (((user.height ?? 1) / 100) * ((user.height ?? 1) / 100));
    String bmiStatus = _getBMIStatus(bmi);
    Color bmiColor = _getBMIColor(bmi);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHỈ SỐ SINH TỒN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textHint, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInteractiveVitalCard(
                  'BMI', 
                  bmi.toStringAsFixed(1), 
                  bmiStatus, 
                  Icons.analytics_rounded, 
                  bmiColor
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInteractiveVitalCard(
                  'NHÓM MÁU', 
                  user.bloodType ?? 'O+', 
                  'Tương thích cao', 
                  Icons.water_drop_rounded, 
                  const Color(0xFFEF4444)
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInteractiveVitalCard(
                  'CHIỀU CAO', 
                  '${user.height ?? "--"} cm', 
                  'Tăng 1.2% year', 
                  Icons.straighten_rounded, 
                  const Color(0xFF3B82F6)
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInteractiveVitalCard(
                  'CÂN NẶNG', 
                  '${user.weight ?? "--"} kg', 
                  'Ổn định', 
                  Icons.monitor_weight_rounded, 
                  const Color(0xFF10B981)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveVitalCard(String label, String value, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 18),
              ),
              Text(
                status,
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textHint)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textBody)),
        ],
      ),
    );
  }

  Widget _buildFamilyCircleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'GIA ĐÌNH CỦA BẠN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textHint, letterSpacing: 1.2),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _familyMembers.length + 1,
            itemBuilder: (context, index) {
              if (index == _familyMembers.length) {
                return _buildAddFamilyButton();
              }
              final member = _familyMembers[index];
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: member['avatarUrl'] != null 
                          ? NetworkImage(member['avatarUrl']) 
                          : null,
                      backgroundColor: AppColors.primaryLight,
                      child: member['avatarUrl'] == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      member['relationship'] ?? 'Người thân',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textBody),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAddFamilyButton() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withOpacity(0.2), style: BorderStyle.none),
            color: AppColors.primary.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_rounded, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        const Text('Thêm mới', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textHint)),
      ],
    );
  }

  Widget _buildInfoTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildMenuSection(
            title: 'THÔNG TIN LIÊN HỆ',
            items: [
              _buildMenuItem(Icons.phone_iphone_rounded, 'Số điện thoại', user.phone, AppColors.primary),
              _buildMenuItem(Icons.email_rounded, 'Email liên hệ', user.email, AppColors.primary),
              _buildMenuItem(Icons.location_on_rounded, 'Địa chỉ thường trú', user.address ?? 'Chưa cập nhật', AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          _buildMenuSection(
            title: 'HỒ SƠ BẢO HIỂM & KHẨN CẤP',
            items: [
              _buildMenuItem(Icons.badge_rounded, 'Số thẻ BHYT', user.healthInsuranceNumber ?? 'Chưa cập nhật', AppColors.success),
              _buildMenuItem(Icons.contact_emergency_rounded, 'Người liên hệ khẩn cấp', user.emergencyPhone ?? 'Chưa thiết lập', AppColors.error),
            ],
          ),
          const SizedBox(height: 30),
          _buildUpdateProfileButton(user),
          const SizedBox(height: 12),
          _buildSyncDataButton(user),
          const SizedBox(height: 12),
          _buildLogoutButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textHint, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [BoxShadow(color: AppColors.textBody.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String value, Color iconColor) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textHint)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textBody)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.border, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateProfileButton(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.editProfile, arguments: user);
          if (result == true) {
            setState(() => _isLoading = true);
            _loadUserProfile();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Text('CẬP NHẬT HỒ SƠ', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildSyncDataButton(UserModel user) {
    return OutlinedButton(
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          await FirebaseDataSeeder.seedAll(user.uid);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã đồng bộ 14 bác sĩ Tim mạch và dữ liệu mẫu thành công!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _loadUserProfile(); // Refresh the page data
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi đồng bộ: $e'), backgroundColor: AppColors.error),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        'ĐỒNG BỘ DỮ LIỆU MẪU (DEV)',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
      },
      child: const Text('ĐĂNG XUẤT HỎI HỆ THỐNG', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
    );
  }

  String _getBMIStatus(double bmi) {
    if (bmi < 18.5) return 'THẤP';
    if (bmi < 24.9) return 'BÌNH THƯỜNG';
    if (bmi < 29.9) return 'TIỀN BÉO PHÌ';
    return 'BÉO PHÌ';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF3B82F6);
    if (bmi < 24.9) return const Color(0xFF10B981);
    if (bmi < 29.9) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  void _showQRCodeDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'MÃ BỆNH NHÂN',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 200, color: AppColors.textBody),
              ),
              const SizedBox(height: 24),
              Text(
                user.fullName.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              Text(
                'ID: ${user.uid.toUpperCase()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ĐÓNG', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._child);

  final Widget _child;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
