import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/user_model.dart';
import '../../../../app/theme/app_colors.dart';

class MedicalEmergencyIdPage extends StatelessWidget {
  const MedicalEmergencyIdPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textBody,
        centerTitle: true,
        title: const Text('MEDICAL ID', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: uid == null 
            ? null 
            : FirebaseFirestore.instance.collection('Users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          UserModel user = snapshot.hasData && snapshot.data!.exists
              ? UserModel.fromDocument(snapshot.data!)
              : UserModel.empty();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                _buildSafetyWarning(),
                const SizedBox(height: 32),
                _buildIdentitiferCard(user),
                const SizedBox(height: 32),
                _buildDetailedInfo(user),
                const SizedBox(height: 40),
                _buildEmergencyContact(user),
                const SizedBox(height: 40),
                _buildBackInstructions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSafetyWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'THÔNG TIN NÀY GIÚP NHÂN VIÊN Y TẾ CỨU HỘ TRONG TÌNH HUỐNG KHẨN CẤP.',
              style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitiferCard(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface, 
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColors.textBody.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Text(user.fullName == '' ? "NGƯỜI DÙNG" : user.fullName.toUpperCase(), style: const TextStyle(color: AppColors.textBody, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('DOB: ${user.dateOfBirth ?? "---"}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background, 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.qr_code_2_rounded, size: 180, color: AppColors.textBody),
          ),
          const SizedBox(height: 32),
          const Text('ID Y TẾ CHUẨN QUỐC TẾ', style: TextStyle(color: AppColors.textHint, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo(UserModel user) {
    return Column(
      children: [
        _buildInfoRow('NHÓM MÁU', user.bloodType ?? 'O+', color: AppColors.error),
        _buildInfoRow('DỊ ỨNG', (user.allergies != null && user.allergies!.isNotEmpty) ? user.allergies!.join(", ") : 'KHÔNG CÓ', color: AppColors.error),
        _buildInfoRow('BỆNH LÝ', (user.chronicConditions != null && user.chronicConditions!.isNotEmpty) ? user.chronicConditions!.join(", ") : 'KHÔNG CÓ', color: AppColors.warning),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          Expanded(
            flex: 7,
            child: Text(value, style: TextStyle(color: color ?? AppColors.textBody, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.textBody.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LIÊN HỆ KHẨN CẤP', style: TextStyle(color: AppColors.textHint, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.phone_in_talk_rounded, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NGƯỜI THÂN (Vợ/Chồng/Con)', style: TextStyle(color: AppColors.textBody, fontSize: 14, fontWeight: FontWeight.w800)),
                  Text(user.emergencyPhone ?? '09x-xxxx-xxx', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackInstructions(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: const Text(
        'NHẤN ĐỂ QUAY LẠI HỒ SƠ CHÍNH',
        style: TextStyle(color: AppColors.textHint, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }
}
