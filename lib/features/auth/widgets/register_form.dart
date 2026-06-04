import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _dateOfBirthController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _fullNameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _cccdFocusNode = FocusNode();
  final _dateOfBirthFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  final Set<String> _touchedFields = <String>{};

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptedPolicy = false;
  bool _submittedOnce = false;
  String _verificationMethod = 'email';
  String? _policyError;

  static const bool kEnablePhoneOtpVerification = bool.fromEnvironment(
    'ENABLE_PHONE_OTP_VERIFICATION',
    defaultValue: false,
  );

  bool get _isFormValid =>
      Validators.validateFullName(_fullNameController.text) == null &&
      Validators.validatePhone(_phoneController.text) == null &&
      Validators.validateCccd(_cccdController.text) == null &&
      Validators.validateDateOfBirth(_dateOfBirthController.text) == null &&
      Validators.validateEmail(_emailController.text) == null &&
      Validators.validatePassword(_passwordController.text) == null &&
      Validators.validateConfirmPassword(
            _confirmPasswordController.text,
            _passwordController.text,
          ) ==
          null;

  bool get _canSubmit => !_isLoading && _acceptedPolicy && _isFormValid;

  @override
  void initState() {
    super.initState();
    _attachTouchListener(_fullNameFocusNode, 'fullName');
    _attachTouchListener(_phoneFocusNode, 'phone');
    _attachTouchListener(_cccdFocusNode, 'cccd');
    _attachTouchListener(_dateOfBirthFocusNode, 'dateOfBirth');
    _attachTouchListener(_emailFocusNode, 'email');
    _attachTouchListener(_passwordFocusNode, 'password');
    _attachTouchListener(_confirmPasswordFocusNode, 'confirmPassword');
  }

  void _attachTouchListener(FocusNode node, String field) {
    node.addListener(() {
      if (!node.hasFocus) _markTouched(field);
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _cccdController.dispose();
    _dateOfBirthController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _fullNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _cccdFocusNode.dispose();
    _dateOfBirthFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _markTouched(String field) {
    if (_touchedFields.contains(field)) return;
    setState(() {
      _touchedFields.add(field);
    });
    _formKey.currentState?.validate();
  }

  void _handleFieldChanged(String field) {
    setState(() {
      _touchedFields.add(field);
      _policyError = null;
    });
    _formKey.currentState?.validate();
  }

  String? _visibleValidator(
    String field,
    String? value,
    String? Function(String?) validator,
  ) {
    if (!_submittedOnce && !_touchedFields.contains(field)) return null;
    return validator(value);
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (_isLoading) return;

    setState(() {
      _submittedOnce = true;
      _touchedFields.addAll(const {
        'fullName',
        'phone',
        'cccd',
        'dateOfBirth',
        'email',
        'password',
        'confirmPassword',
      });
      _policyError = _acceptedPolicy
          ? null
          : 'Bạn cần đồng ý với chính sách trước khi đăng ký.';
    });

    final valid = _formKey.currentState!.validate();
    if (!valid || !_acceptedPolicy) {
      _focusFirstInvalidField();
      if (!_acceptedPolicy) _showMessage(_policyError!);
      return;
    }

    if (_verificationMethod == 'phone' && !kEnablePhoneOtpVerification) {
      _showMessage('OTP SĐT chưa được bật trong bản build hiện tại.');
      return;
    }

    if (_verificationMethod == 'phone' && kIsWeb) {
      _showMessage('OTP SĐT chưa hỗ trợ trên Web.');
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
          dateOfBirth: Validators.parseDateOfBirth(
            _dateOfBirthController.text,
          )!,
        ),
      );

      if (!mounted) return;

      final email = _emailController.text.trim();
      if (_verificationMethod == 'phone') {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.verifyPhone,
          arguments: {'phone': _phoneController.text.trim(), 'email': email},
        );
      } else {
        _showMessage(
          'Đăng ký thành công. Vui lòng kiểm tra email để xác thực tài khoản.',
          isError: false,
        );
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.registerSuccess,
          arguments: email,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(_mapAuthError(e));
    } catch (e) {
      _showMessage(
        e.toString().replaceAll('Exception: ', '').trim().isEmpty
            ? 'Đăng ký thất bại.'
            : e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _focusFirstInvalidField() {
    final checks = <({FocusNode node, String? error})>[
      (
        node: _fullNameFocusNode,
        error: Validators.validateFullName(_fullNameController.text),
      ),
      (
        node: _phoneFocusNode,
        error: Validators.validatePhone(_phoneController.text),
      ),
      (
        node: _cccdFocusNode,
        error: Validators.validateCccd(_cccdController.text),
      ),
      (
        node: _dateOfBirthFocusNode,
        error: Validators.validateDateOfBirth(_dateOfBirthController.text),
      ),
      (
        node: _emailFocusNode,
        error: Validators.validateEmail(_emailController.text),
      ),
      (
        node: _passwordFocusNode,
        error: Validators.validatePassword(_passwordController.text),
      ),
      (
        node: _confirmPasswordFocusNode,
        error: Validators.validateConfirmPassword(
          _confirmPasswordController.text,
          _passwordController.text,
        ),
      ),
    ];

    for (final check in checks) {
      if (check.error != null) {
        check.node.requestFocus();
        return;
      }
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
        color: Colors.white.withValues(alpha: 0.97),
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
        autovalidateMode: AutovalidateMode.disabled,
        child: Column(
          children: [
            const AppLogoHeader(
              title: 'Đăng ký tài khoản',
              subtitle: 'Điền thông tin để bắt đầu sử dụng hệ thống.',
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _fullNameController,
              focusNode: _fullNameFocusNode,
              label: 'Họ tên',
              hintText: 'Nguyễn Văn A',
              prefixIcon: Icons.person_outline,
              validator: (value) => _visibleValidator(
                'fullName',
                value,
                Validators.validateFullName,
              ),
              onChanged: (_) => _handleFieldChanged('fullName'),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_phoneFocusNode);
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              label: 'Số điện thoại',
              hintText: '0123456789',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  _visibleValidator('phone', value, Validators.validatePhone),
              onChanged: (_) => _handleFieldChanged('phone'),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_cccdFocusNode);
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _cccdController,
              focusNode: _cccdFocusNode,
              label: 'CCCD',
              hintText: 'Nhập 12 số CCCD',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) =>
                  _visibleValidator('cccd', value, Validators.validateCccd),
              onChanged: (_) => _handleFieldChanged('cccd'),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_dateOfBirthFocusNode);
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _dateOfBirthController,
              focusNode: _dateOfBirthFocusNode,
              label: 'Ngày sinh',
              hintText: 'dd/MM/yyyy',
              prefixIcon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [_DateOfBirthInputFormatter()],
              validator: (value) => _visibleValidator(
                'dateOfBirth',
                value,
                Validators.validateDateOfBirth,
              ),
              onChanged: (_) => _handleFieldChanged('dateOfBirth'),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_emailFocusNode);
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              label: 'Email',
              hintText: 'abc@gmail.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  _visibleValidator('email', value, Validators.validateEmail),
              onChanged: (_) => _handleFieldChanged('email'),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'Mật khẩu',
              hintText: 'Nhập mật khẩu',
              obscureText: _obscurePassword,
              validator: (value) => _visibleValidator(
                'password',
                value,
                Validators.validatePassword,
              ),
              onChanged: (_) => _handleFieldChanged('password'),
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
            const SizedBox(height: 14),
            CustomTextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              label: 'Xác nhận mật khẩu',
              hintText: 'Nhập lại mật khẩu',
              obscureText: _obscureConfirmPassword,
              validator: (value) => _visibleValidator(
                'confirmPassword',
                value,
                (input) => Validators.validateConfirmPassword(
                  input,
                  _passwordController.text,
                ),
              ),
              onChanged: (_) => _handleFieldChanged('confirmPassword'),
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
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Phương thức xác thực tài khoản',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF13223E),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _VerificationMethodTile(
                    selected: _verificationMethod == 'email',
                    icon: Icons.email_outlined,
                    label: 'Xác thực Email',
                    onTap: () {
                      setState(() => _verificationMethod = 'email');
                    },
                  ),
                ),
                if (kEnablePhoneOtpVerification) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _VerificationMethodTile(
                      selected: _verificationMethod == 'phone',
                      icon: Icons.phone_android_outlined,
                      label: 'Xác thực OTP SĐT',
                      onTap: () {
                        setState(() => _verificationMethod = 'phone');
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _acceptedPolicy = !_acceptedPolicy;
                        _policyError = null;
                      });
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedPolicy,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _acceptedPolicy = value ?? false;
                                _policyError = null;
                              });
                            },
                      activeColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textBody,
                            height: 1.45,
                          ),
                          children: [
                            const TextSpan(text: 'Tôi đã đọc và đồng ý với '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.termsOfUse,
                                  );
                                },
                                child: const Text(
                                  'Điều khoản sử dụng',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' và '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.privacyPolicy,
                                  );
                                },
                                child: const Text(
                                  'Chính sách bảo mật',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' của ứng dụng.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_policyError != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _policyError!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            CustomButton(
              text: 'Đăng ký',
              isLoading: _isLoading,
              onPressed: _canSubmit ? _handleRegister : null,
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

class _VerificationMethodTile extends StatelessWidget {
  const _VerificationMethodTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF1FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1565C0) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1565C0)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF13223E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateOfBirthInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();

    for (var i = 0; i < limited.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(limited[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
