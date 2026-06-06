import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/payment_model.dart';
import 'payment_status_badge.dart';

class PaymentTimeline extends StatelessWidget {
  const PaymentTimeline({super.key, required this.payment});

  final PatientPaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final events = <_TimelineEvent>[
      _TimelineEvent('Tạo hóa đơn', payment.createdAt),
      if (payment.updatedAt != null)
        _TimelineEvent(
          PaymentStatusBadge.statusLabel(payment.status),
          payment.updatedAt!,
        ),
      if (payment.paidAt != null)
        _TimelineEvent('Thanh toán thành công', payment.paidAt!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trạng thái',
          style: TextStyle(
            color: AppColors.textBody,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...events.map((event) => _TimelineRow(event: event)),
      ],
    );
  }
}

class _TimelineEvent {
  const _TimelineEvent(this.title, this.time);

  final String title;
  final DateTime time;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});

  final _TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.title,
              style: TextStyle(
                color: AppColors.textBody,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(event.time),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
