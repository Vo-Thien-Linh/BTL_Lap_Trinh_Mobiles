import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../config/service_locator.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/utils/firebase_data_seeder.dart';
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
      _showMessage('Vui lòng kiểm tra lại email hoặc mật khẩu.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appUser = await _loginUsecase.call(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Đã tối ưu: Bỏ qua reload dư thừa để vào app ngay lập tức
      // await FirebaseAuth.instance.currentUser?.reload();

      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (user != null && !user.emailVerified) {
        _showMessage(
          'Email chưa được xác thực. Vui lòng kiểm tra hộp thư.',
          isError: false,
        );

        Navigator.pushReplacementNamed(context, AppRoutes.verifyEmail);
        return;
      }

      // đã verify
      _showMessage('Đăng nhập thành công.', isError: false);

      final targetRoute = _resolveHomeRouteByRole(appUser.role);
      Navigator.pushReplacementNamed(context, targetRoute);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(_mapAuthError(error));
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDemoLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      const email = 'demo@medical.com';
      const password = 'Password123!';

      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // Tạo tài khoản demo nều chưa có
          userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final uid = userCredential.user!.uid;
      
      // Seed dữ liệu
      await FirebaseDataSeeder.seedAll(uid);

      if (!mounted) return;
      _showMessage('Chào mừng bạn đến với bản thử nghiệm!', isError: false);
      
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Lỗi khởi tạo Demo: ${e.toString()}');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _resolveHomeRouteByRole(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return AppRoutes.doctorHome;
      case 'admin':
        return AppRoutes.home;
      case 'patient':
      default:
        return AppRoutes.home;
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Email hoặc mật khẩu không đúng.';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
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
              title: 'Đăng nhập',
              subtitle:
                  'Chào mừng bạn đến với hệ thống đặt lịch khám bệnh.\nVui lòng đăng nhập để tiếp tục.',
            ),
            const SizedBox(height: 28),
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              hintText: 'Nhập email của bạn',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
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
            const SizedBox(height: 8),
            CustomButton(
              text: 'Đăng nhập',
              isLoading: _isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : _handleDemoLogin,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: const BorderSide(color: AppColors.primary, width: 1),
                foregroundColor: AppColors.primary,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'TRẢI NGHIỆM DEMO (1-CHẠM)',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ],
              ),
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
