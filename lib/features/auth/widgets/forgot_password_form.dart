import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../config/service_locator.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/app_logo_header.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../domain/usecases/forgot_password_usecase.dart';

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ForgotPasswordUsecase _forgotPasswordUsecase =
  getIt<ForgotPasswordUsecase>();

  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      _showMessage('Vui lòng nhập email hợp lệ.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _forgotPasswordUsecase.call(_emailController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showMessage(
        'Đã gửi email đặt lại mật khẩu. Vui lòng kiểm tra hộp thư.',
        isError: false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(_mapAuthError(error));
    } catch (_) {
      if (!mounted) return;
      _showMessage('Không thể gửi yêu cầu lúc này. Vui lòng thử lại.');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'too-many-requests':
        return 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Kết nối mạng không ổn định. Vui lòng thử lại.';
      default:
        return error.message ?? 'Gửi email thất bại. Vui lòng thử lại.';
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
              title: 'Khôi phục mật khẩu',
              subtitle:
              'Nhập email đã đăng ký để nhận hướng dẫn đặt lại mật khẩu.',
            ),
            const SizedBox(height: 28),
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              hintText: 'Nhập email đã đăng ký',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleResetPassword(),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Gửi yêu cầu',
              isLoading: _isLoading,
              onPressed: _handleResetPassword,
            ),
          ],
        ),
      ),
    );
  }
}