import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/payment_model.dart';

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({super.key, required this.payments});

  final List<PatientPaymentModel> payments;

  @override
  Widget build(BuildContext context) {
    final paid = payments
        .where((payment) => payment.status == 'paid')
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final waiting = payments
        .where((payment) => payment.status != 'paid')
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    return Container(
      margin: EdgeInsets.fromLTRB(20, 16, 20, 12),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(label: 'Cần thanh toán', amount: waiting),
          ),
          Container(width: 1, height: 42, color: AppColors.border),
          Expanded(
            child: _Metric(label: 'Đã thanh toán', amount: paid),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '${NumberFormat('#,###').format(amount)} đ',
            style: TextStyle(
              color: AppColors.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
