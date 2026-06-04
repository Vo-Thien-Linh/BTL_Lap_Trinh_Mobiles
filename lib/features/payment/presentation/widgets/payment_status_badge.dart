import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        statusLabel(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Đã thanh toán';
      case 'payos_pending':
      case 'qr_generated':
        return 'Đang thanh toán payOS';
      case 'waiting_confirmation':
        return 'Chờ xác nhận';
      case 'pay_at_counter':
        return 'Thanh toán tại quầy';
      case 'cancelled':
        return 'Đã hủy';
      case 'expired':
        return 'Hết hạn';
      case 'failed':
        return 'Thất bại';
      case 'pending':
        return 'Chờ thanh toán';
      case 'unpaid':
      default:
        return 'Chưa thanh toán';
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'payos_pending':
      case 'qr_generated':
      case 'waiting_confirmation':
      case 'pay_at_counter':
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
      case 'expired':
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
