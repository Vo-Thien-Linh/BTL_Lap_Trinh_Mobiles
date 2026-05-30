import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';

class EmergencyContactPage extends StatefulWidget {
  const EmergencyContactPage({super.key});

  @override
  State<EmergencyContactPage> createState() => _EmergencyContactPageState();
}

class _EmergencyContactPageState extends State<EmergencyContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _currentPhone;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyContact() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Người dùng chưa đăng nhập');

      final uid = user.uid;
      // Load user profile from either 'users' or 'Users'
      var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      }

      if (doc.exists) {
        final data = doc.data();
        _currentPhone = data?['emergencyPhone'] as String?;
        _controller.text = _currentPhone ?? '';
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Không thể tải thông tin liên hệ khẩn cấp: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveEmergencyContact() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Người dùng chưa đăng nhập');

      final uid = user.uid;
      final phone = _controller.text.trim();

      final updatedData = <String, dynamic>{
        'emergencyPhone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final batch = FirebaseFirestore.instance.batch();
      
      // Update both collections to keep data in sync
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(uid),
        updatedData,
        SetOptions(merge: true),
      );
      batch.set(
        FirebaseFirestore.instance.collection('Users').doc(uid),
        updatedData,
        SetOptions(merge: true),
      );

      await batch.commit();

      if (!mounted) return;
      _showSnackBar('Cập nhật người liên hệ khẩn cấp thành công.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Không thể lưu thông tin: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  String? _validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại khẩn cấp';
    }
    final trimmed = val.trim();
    // Allow standard format starting with 0/+/+84, between 9 and 12 characters.
    final phoneRegExp = RegExp(r'^\+?[0-9]{9,12}$');
    if (!phoneRegExp.hasMatch(trimmed)) {
      return 'Số điện thoại không đúng định dạng';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Người liên hệ khẩn cấp'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textBody,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 18),
                    _buildFormCard(),
                    const SizedBox(height: 18),
                    _buildNoteCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    final hasPhone = _currentPhone != null && _currentPhone!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.contact_emergency_rounded,
                  color: AppColors.error,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Người liên hệ khẩn cấp',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textBody,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Thông tin liên lạc khẩn cấp khi gặp sự cố y khoa',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (hasPhone) ...[
            Text(
              _currentPhone!,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textBody,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (hasPhone ? AppColors.success : AppColors.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              hasPhone ? 'Đã thiết lập' : 'Chưa thiết lập',
              style: TextStyle(
                color: hasPhone ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    final hasPhone = _currentPhone != null && _currentPhone!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasPhone ? 'Cập nhật số điện thoại' : 'Thiết lập số điện thoại',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textBody,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              ],
              decoration: InputDecoration(
                labelText: 'Số điện thoại khẩn cấp',
                hintText: 'Ví dụ: 0912345678',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              validator: _validatePhone,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEmergencyContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Lưu liên hệ khẩn cấp',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Lưu ý: Số điện thoại khẩn cấp sẽ hiển thị trên ID Y tế (Medical ID) của bạn để nhân viên cứu hộ có thể liên lạc ngay lập tức trong trường hợp khẩn cấp mà không cần mở khóa thiết bị.',
              style: TextStyle(height: 1.45, fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
