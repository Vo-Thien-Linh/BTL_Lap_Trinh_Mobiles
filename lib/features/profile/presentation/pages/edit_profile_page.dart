import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/user_model.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _cccdController;
  late TextEditingController _healthInsuranceController;
  
  String? _selectedGender;
  String? _avatarUrl;
  File? _selectedImage;
  bool _isUploadingAvatar = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone);
    _dobController = TextEditingController(text: widget.user.dateOfBirth ?? '');
    _cccdController = TextEditingController(text: widget.user.cccd);
    _healthInsuranceController = TextEditingController(text: widget.user.healthInsuranceNumber ?? '');
    
    _avatarUrl = widget.user.avatarUrl;
    
    final gender = widget.user.gender;
    if (gender == 'Nam' || gender == 'Nữ' || gender == 'Khác') {
      _selectedGender = gender;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _cccdController.dispose();
    _healthInsuranceController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _isUploadingAvatar = true;
      });

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${widget.user.uid}.jpg');
      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();
      
      setState(() {
        _avatarUrl = downloadUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tải ảnh đại diện thành công!'),
          backgroundColor: Color(0xFF2E7D32),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi (Cần cấp quyền Web/Khởi động lại app): $e'),
          backgroundColor: const Color(0xFFB3261E),
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    DateTime? initialDate;
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parseLoose(_dobController.text);
      } catch (_) {}
    }
    initialDate ??= DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F49B8),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String? _validateBHYT(String? val) {
    if (val == null || val.trim().isEmpty) {
      // Allow empty if age >= 60
      if (_dobController.text.isNotEmpty) {
        try {
          final dob = DateFormat('dd/MM/yyyy').parseLoose(_dobController.text);
          final age = DateTime.now().year - dob.year;
          if (age >= 60) return null;
        } catch (_) {}
      }
      return 'Bắt buộc nhập mã BHYT đối với người dưới 60 tuổi';
    }

    final trimmed = val.trim();
    if (trimmed.length != 10 && trimmed.length != 15) {
      return 'Mã BHYT phải có chính xác 10 hoặc 15 ký tự';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isUploadingAvatar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đợi tải ảnh xong!')),
      );
      return;
    }

    setState(() { _isSaving = true; });

    try {
      final updatedData = {
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'gender': _selectedGender,
        'cccd': _cccdController.text.trim(),
        'healthInsuranceNumber': _healthInsuranceController.text.trim(),
        if (_avatarUrl != null) 'avatarUrl': _avatarUrl,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: const Color(0xFFB3261E),
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(
            color: Color(0xFF131826),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF131826)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    Container(
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
                        child: _isUploadingAvatar
                            ? const Center(child: CircularProgressIndicator(color: Colors.white))
                            : _selectedImage != null
                                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                : _avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? Image.network(_avatarUrl!, fit: BoxFit.cover)
                                    : const Icon(Icons.person, color: Colors.white, size: 50),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0A3DA8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Thông tin cá nhân',
                style: TextStyle(
                  color: Color(0xFF0A3DA8),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _fullNameController,
                label: 'Họ và tên',
                icon: Icons.person_outline,
                validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),

              // Date of Birth Field (Read Only, DatePicker)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _selectDate,
                  style: const TextStyle(
                    color: Color(0xFF131826),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  decoration: _buildInputDecoration(
                    label: 'Ngày sinh (DD/MM/YYYY)',
                    icon: Icons.cake_outlined,
                  ),
                ),
              ),

              // Gender Dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  items: ['Nam', 'Nữ', 'Khác'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                  style: const TextStyle(
                    color: Color(0xFF131826),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  decoration: _buildInputDecoration(
                    label: 'Giới tính (Nam/Nữ)',
                    icon: Icons.wc_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Thông tin định danh',
                style: TextStyle(
                  color: Color(0xFF0A3DA8),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _cccdController,
                label: 'Số CCCD',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: _healthInsuranceController,
                label: 'Mã số BHYT',
                hintText: 'Người trên 60 tuổi không cần nhập mã BHYT',
                icon: Icons.health_and_safety_outlined,
                validator: _validateBHYT,
              ),
              const SizedBox(height: 24),
              const Text(
                'Thông tin liên hệ',
                style: TextStyle(
                  color: Color(0xFF0A3DA8),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Số điện thoại',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving || _isUploadingAvatar ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F49B8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9EA3B0),
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF7B7F8D),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF0A3DA8), size: 22),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0A3DA8), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          color: Color(0xFF131826),
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        decoration: _buildInputDecoration(
          label: label,
          icon: icon,
          hintText: hintText,
        ),
      ),
    );
  }
}
