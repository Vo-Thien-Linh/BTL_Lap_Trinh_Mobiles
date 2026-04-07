import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isLoading = false;

  Future<void> _checkVerified() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;

    await user?.reload();

    if (user != null && user.emailVerified) {
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showMessage('Bạn vẫn chưa xác thực email.');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _resendEmail() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await user.sendEmailVerification();
      _showMessage('Đã gửi lại email xác thực.');
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Vui lòng xác thực email của bạn',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(user?.email ?? ''),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _checkVerified,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Tôi đã xác thực'),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: _resendEmail,
              child: const Text('Gửi lại email'),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: _logout,
              child: const Text('Quay lại trang đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}