import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../config/service_locator.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/app_logo_header.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/form_switch_text.dart';
import '../domain/usecases/login_usecase.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LoginUsecase _loginUsecase = getIt<LoginUsecase>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) {
      _showMessage('Vui lòng kiểm tra lại tài khoản hoặc mật khẩu.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appUser = await _loginUsecase.call(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (!mounted) return;

      final canContinue = await _validateLoginAccess(appUser, firebaseUser);
      if (!mounted || !canContinue) return;

      _showMessage('Đăng nhập thành công.', isError: false);
      Navigator.pushReplacementNamed(
        context,
        _resolveHomeRouteByRole(appUser.role),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(_mapAuthError(error));
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _validateLoginAccess(dynamic appUser, User? firebaseUser) async {
    final role = appUser.role.toString().toLowerCase();
    final status = appUser.status.toString().toLowerCase();

    if (status != 'active') {
      await FirebaseAuth.instance.signOut();
      throw Exception('Tài khoản chưa được kích hoạt hoặc đã bị khóa.');
    }

    if (role == 'doctor') {
      final uid = firebaseUser?.uid ?? appUser.uid.toString();
      final doctorSnapshot = await FirebaseFirestore.instance
          .collection('Doctors')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (doctorSnapshot.docs.isEmpty) {
        await FirebaseAuth.instance.signOut();
        throw Exception('Không tìm thấy hồ sơ bác sĩ được cấp quyền.');
      }

      final doctorData = doctorSnapshot.docs.first.data();
      final verificationStatus =
          doctorData['verificationStatus']?.toString().toLowerCase() ?? '';
      final isActive = doctorData['isActive'] != false;
      final isVerified =
          verificationStatus == 'verified' || verificationStatus == 'approved';

      if (!isActive || !isVerified) {
        await FirebaseAuth.instance.signOut();
        throw Exception('Tài khoản bác sĩ chưa được web admin xác minh.');
      }

      return true;
    }

    final isVerified =
        appUser.emailVerified ||
        (firebaseUser != null && firebaseUser.emailVerified);
    if (!isVerified) {
      _showMessage(
        'Tài khoản chưa được xác thực. Vui lòng kiểm tra hộp thư hoặc mã OTP.',
      );
      Navigator.pushReplacementNamed(context, AppRoutes.verifyEmail);
      return false;
    }

    return true;
  }

  String _resolveHomeRouteByRole(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return AppRoutes.doctorHome;
      case 'admin':
      case 'patient':
      default:
        return AppRoutes.home;
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Email hoặc số điện thoại không hợp lệ.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Tài khoản hoặc mật khẩu không đúng.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Bạn đã thử quá nhiều lần. Vui lòng đợi ít phút rồi thử lại.';
      case 'email-not-verified':
        return 'Email chưa được xác thực. Vui lòng kiểm tra hộp thư.';
      default:
        return error.message ?? 'Đăng nhập thất bại. Vui lòng thử lại.';
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

  void _startGuestExperience() {
    Navigator.pushNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              title: 'Đăng nhập',
              subtitle:
                  'Chào mừng bạn đến với hệ thống đặt lịch khám bệnh.\nVui lòng đăng nhập để tiếp tục.',
            ),
            const SizedBox(height: 28),
            CustomTextField(
              controller: _emailController,
              label: 'Email hoặc số điện thoại',
              hintText: 'Nhập email hoặc số điện thoại của bạn',
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.text,
              validator: Validators.validateEmailOrPhone,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'Mật khẩu',
              hintText: 'Nhập mật khẩu',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              validator: Validators.validatePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pushNamed(context, AppRoutes.forgotPassword);
                      },
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: 14),
            CustomButton(
              text: 'Đăng nhập',
              isLoading: _isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _startGuestExperience,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.primaryDark,
                backgroundColor: const Color(0xFFF7FBFF),
                side: const BorderSide(color: AppColors.primaryDark),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Trải nghiệm thử app'),
            ),
            const SizedBox(height: 18),
            FormSwitchText(
              normalText: 'Bạn chưa có tài khoản? ',
              actionText: 'Đăng ký ngay',
              onTap: _isLoading
                  ? () {}
                  : () {
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
