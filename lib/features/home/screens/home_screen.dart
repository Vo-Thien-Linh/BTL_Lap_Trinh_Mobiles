import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Text(
            'Đăng nhập thành công.\nĐây là trang chủ giả lập của hệ thống đặt lịch khám bệnh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}