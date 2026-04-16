import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../config/service_locator.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/app_logo_header.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/form_switch_text.dart';
import '../domain/entities/register_request_entity.dart';
import '../domain/usecases/register_usecase.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _registerUsecase = getIt<RegisterUsecase>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cccdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _phoneFocusNode = FocusNode();
  final _cccdFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptedTerms = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _cccdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _phoneFocusNode.dispose();
    _cccdFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      _showMessage('Thông tin chưa hợp lệ.');
      return;
    }

    if (!_acceptedTerms) {
      _showMessage('Bạn cần đồng ý điều khoản.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _registerUsecase.call(
        RegisterRequestEntity(
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          cccd: _cccdController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.registerSuccess,
        arguments: _emailController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_mapAuthError(e));
    } catch (_) {
      _showMessage('Đăng ký thất bại.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email đã tồn tại.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'too-many-requests':
        return 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.';
      default:
        return e.message ?? 'Lỗi đăng ký.';
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            const AppLogoHeader(
              title: 'Đăng ký tài khoản',
              subtitle: 'Điền thông tin để bắt đầu sử dụng hệ thống.',
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _fullNameController,
              label: 'Họ tên',
              hintText: 'Nguyễn Văn A',
              prefixIcon: Icons.person_outline,
              validator: Validators.validateFullName,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_phoneFocusNode);
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              label: 'Số điện thoại',
              hintText: '0123456789',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_cccdFocusNode);
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _cccdController,
              focusNode: _cccdFocusNode,
              label: 'CCCD',
              hintText: 'Nhập 12 số CCCD',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              validator: Validators.validateCccd,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_emailFocusNode);
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              label: 'Email',
              hintText: 'abc@gmail.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'Mật khẩu',
              hintText: 'Nhập mật khẩu',
              obscureText: _obscurePassword,
              validator: Validators.validatePassword,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              label: 'Xác nhận mật khẩu',
              hintText: 'Nhập lại mật khẩu',
              obscureText: _obscureConfirmPassword,
              validator: (value) => Validators.validateConfirmPassword(
                value,
                _passwordController.text,
              ),
              prefixIcon: Icons.lock_reset_outlined,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleRegister(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _acceptedTerms,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _acceptedTerms = value ?? false;
                      });
                    },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Tôi đồng ý với điều khoản sử dụng của hệ thống.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Đăng ký',
              isLoading: _isLoading,
              onPressed: _handleRegister,
            ),
            const SizedBox(height: 16),
            FormSwitchText(
              normalText: 'Đã có tài khoản? ',
              actionText: 'Đăng nhập',
              onTap: _isLoading
                  ? () {}
                  : () {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
