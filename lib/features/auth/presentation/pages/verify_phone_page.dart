import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';

class VerifyPhonePage extends StatefulWidget {
  const VerifyPhonePage({super.key, required this.phone, required this.email});

  final String phone;
  final String email;

  @override
  State<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage> {
  final TextEditingController _codeController = TextEditingController();

  bool _isSending = false;
  bool _isVerifying = false;

  String? _verificationId;
  int? _forceResendingToken;

  DateTime? _nextResendAt;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Auto-send OTP on entry.
    unawaited(_sendCode());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  String _normalizeToE164(String input) {
    var value = input.trim();
    if (value.isEmpty) return '';

    value = value.replaceAll(RegExp(r'\s+'), '');
    value = value.replaceAll('-', '');

    if (value.startsWith('+')) return value;

    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    // VN default: convert 0xxxxxxxxx or 84xxxxxxxxx => +84xxxxxxxxx
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.startsWith('84')) digits = digits.substring(2);

    return '+84$digits';
  }

  bool get _canResend {
    final at = _nextResendAt;
    if (at == null) return true;
    return DateTime.now().isAfter(at);
  }

  void _startResendCooldown() {
    _ticker?.cancel();
    _nextResendAt = DateTime.now().add(const Duration(seconds: 30));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_canResend) {
        _ticker?.cancel();
      }
      setState(() {});
    });
  }

  Future<void> _sendCode() async {
    if (_isSending) return;

    if (kIsWeb) {
      _showMessage('Xác thực OTP SĐT chưa hỗ trợ cho Web trong app này.');
      return;
    }

    final phoneE164 = _normalizeToE164(widget.phone);
    if (phoneE164.isEmpty) {
      _showMessage('Số điện thoại không hợp lệ.');
      return;
    }

    if (!_canResend) {
      setState(() {});
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneE164,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _forceResendingToken,
        verificationCompleted: (credential) async {
          // Android can auto-verify instantly.
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          try {
            await user.linkWithCredential(credential);
          } catch (_) {
            // If already linked, try updatePhoneNumber.
            try {
              await user.updatePhoneNumber(credential);
            } catch (_) {}
          }

          await _markPhoneVerified(phoneE164);

          if (!mounted) return;
          _goNext();
        },
        verificationFailed: (e) {
          _showMessage(e.message ?? 'Gửi OTP thất bại.');
        },
        codeSent: (verificationId, forceResendingToken) {
          setState(() {
            _verificationId = verificationId;
            _forceResendingToken = forceResendingToken;
          });
          _startResendCooldown();
          _showMessage('Đã gửi mã OTP đến $phoneE164');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          setState(() => _verificationId = verificationId);
        },
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Không thể gửi OTP.');
    } catch (e) {
      _showMessage('Không thể gửi OTP: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  Future<void> _markPhoneVerified(String phoneE164) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'phoneVerified': true,
      'phoneE164': phoneE164,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _verifyCode() async {
    if (_isVerifying) return;

    final verificationId = _verificationId;
    if (verificationId == null || verificationId.isEmpty) {
      _showMessage('Vui lòng bấm gửi mã OTP trước.');
      return;
    }

    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showMessage('Vui lòng nhập đủ 6 chữ số.');
      return;
    }

    final phoneE164 = _normalizeToE164(widget.phone);

    setState(() => _isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Phiên đăng ký đã hết. Vui lòng đăng ký lại.');
        return;
      }

      try {
        await user.linkWithCredential(credential);
      } catch (_) {
        // If already linked, try update.
        await user.updatePhoneNumber(credential);
      }

      if (phoneE164.isNotEmpty) {
        await _markPhoneVerified(phoneE164);
      }

      if (!mounted) return;
      _goNext();
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Mã OTP không hợp lệ.');
    } catch (e) {
      _showMessage('Xác thực OTP thất bại: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isVerifying = false);
    }
  }

  void _goNext() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.registerSuccess,
      arguments: widget.email,
    );
  }

  Future<void> _cancel() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final phoneE164 = _normalizeToE164(widget.phone);

    String resendText = 'Gửi lại mã';
    if (!_canResend && _nextResendAt != null) {
      final seconds = _nextResendAt!.difference(DateTime.now()).inSeconds;
      resendText = 'Gửi lại mã (${seconds.clamp(0, 30)}s)';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FF),
      appBar: AppBar(
        title: const Text('Xác thực số điện thoại'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _isSending || _isVerifying ? null : _cancel,
            child: const Text('Hủy'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A4FA8).withOpacity(0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    child: Icon(
                      Icons.phone_iphone_rounded,
                      size: 84,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Nhập mã OTP để xác thực',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF13223E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      phoneE164.isEmpty ? widget.phone : phoneE164,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF19406F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Chúng tôi sẽ gửi mã 6 chữ số qua SMS. Sau khi nhận mã, nhập vào ô bên dưới để tiếp tục.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF5B6780),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Xác thực OTP'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: (_isSending || !_canResend) ? null : _sendCode,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(resendText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
