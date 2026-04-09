import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../data/models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userModel = UserModel.fromDocument(doc);
          });
        }
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
        backgroundColor: Color(0xFFF2F4FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0F49B8))),
      );
    }

    if (_userModel == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F4FA),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Không tìm thấy thông tin hồ sơ.')),
      );
    }

    final user = _userModel!;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      appBar: AppBar(
        title: const Text(
          'Hồ sơ của bạn',
          style: TextStyle(
            color: Color(0xFF131826),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF131826)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            // Avatar
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0E8B8E),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipOval(
                  child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? Image.network(user.avatarUrl!, fit: BoxFit.cover, width: 100, height: 100)
                      : const Center(child: Icon(Icons.person, color: Colors.white, size: 50)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName.isNotEmpty ? user.fullName : user.username,
              style: const TextStyle(
                color: Color(0xFF131826),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE4ECFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.role.name.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF0A3DA8),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  _buildInfoTile('Ngày sinh', user.dateOfBirth, Icons.cake_rounded),
                  _buildDivider(),
                  _buildInfoTile('Giới tính', user.gender, Icons.wc_rounded),
                  _buildDivider(),
                  _buildInfoTile('CCCD', user.cccd, Icons.badge_rounded),
                  _buildDivider(),
                  _buildInfoTile('Mã số BHYT', user.healthInsuranceNumber, Icons.health_and_safety_rounded),
                  _buildDivider(),
                  _buildInfoTile('Số điện thoại', user.phone, Icons.phone_rounded),
                  _buildDivider(),
                  _buildInfoTile('Email', user.email, Icons.email_rounded),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Edit Button
            GestureDetector(
              onTap: () async {
                final result = await Navigator.pushNamed(context, '/edit-profile', arguments: user);
                if (result == true) {
                  setState(() { _isLoading = true; });
                  _loadUserProfile();
                }
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F49B8), Color(0xFF1F5CC0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1C57BE).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Chỉnh sửa hồ sơ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String? value, IconData icon) {
    final hasValue = value != null && value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0A3DA8), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7B7F8D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasValue ? value : 'Đang cập nhật',
                  style: TextStyle(
                    color: hasValue ? const Color(0xFF131826) : const Color(0xFF9EA3B0),
                    fontSize: 16,
                    fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                    fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: Color(0xFFF2F4FA),
    );
  }
}
