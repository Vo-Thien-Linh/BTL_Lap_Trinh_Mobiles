import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../appointment/data/models/invoice_models.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/payment_status_badge.dart';
import '../widgets/payment_timeline.dart';

class PaymentDetailPage extends StatefulWidget {
  const PaymentDetailPage({super.key, required this.initialPayment});

  final PatientPaymentModel initialPayment;

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  final _repository = PatientPaymentRepositoryImpl();
  bool _isCreatingPayosLink = false;
  bool _isChoosingCash = false;
  bool _successNotified = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PatientPaymentModel?>(
      stream: _repository.watchPaymentByPath(widget.initialPayment.sourcePath),
      initialData: widget.initialPayment,
      builder: (context, snapshot) {
        final payment = snapshot.data ?? widget.initialPayment;
        _notifyPaidOnce(payment);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textBody,
            elevation: 0,
            title: const Text(
              'Chi ti?t thanh to?n',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                tooltip: 'L?m m?i tr?ng th?i',
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StatusHeader(payment: payment),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Thong tin cuoc hen',
                rows: [
                  _InfoRow('M? thanh to?n', payment.paymentCode),
                  if (payment.invoiceCode.isNotEmpty &&
                      payment.invoiceCode != payment.paymentCode)
                    _InfoRow('M? h?a ??n', payment.invoiceCode),
                  _InfoRow(
                    'B?c s?',
                    payment.doctorName.isEmpty ? '-' : payment.doctorName,
                  ),
                  _InfoRow(
                    'Chuy?n khoa',
                    payment.specialtyName.isEmpty ? '-' : payment.specialtyName,
                  ),
                  _InfoRow(
                    'Ng?y kh?m',
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(payment.appointmentDate ?? payment.createdAt),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PriceCard(payment: payment),
              const SizedBox(height: 16),
              _Card(child: PaymentTimeline(payment: payment)),
              const SizedBox(height: 16),
              _buildActionSection(payment),
              SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionSection(PatientPaymentModel payment) {
    if (payment.status == 'paid') {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thanh to?n th?nh c?ng',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text('S? ti?n: ${NumberFormat('#,###').format(payment.amount)} ?'),
            if (payment.paidAt != null)
              Text(
                'Th?i gian: ${DateFormat('dd/MM/yyyy HH:mm').format(payment.paidAt!)}',
              ),
            if (payment.gatewayTransactionId.isNotEmpty)
              Text('M? giao ??ch: ${payment.gatewayTransactionId}'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.digitalReceipt,
                arguments: _toInvoice(payment),
              ),
              icon: Icon(Icons.receipt_long_rounded),
              label: Text('Xem bi?n nh?n'),
            ),
          ],
        ),
      );
    }

    if (payment.status == 'pay_at_counter') {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thanh to?n t?i qu?y',
              style: TextStyle(
                color: AppColors.textBody,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 12),
            SelectableText(
              payment.paymentCode,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vui l?ng ??a m? h?a ??n n?y cho nh?n vi?n t?i qu?y. Nh?n vi?n s? x?c nh?n ?? thanh to?n sau khi thu ti?n.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
          ],
        ),
      );
    }

    if (payment.status == 'payos_pending' || payment.status == 'qr_generated') {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '?ang ch? thanh to?n payOS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'Sau khi b?n thanh to?n, backend/webhook s? c?p nh?t tr?ng th?i. App s? t? ??i sang th?nh c?ng.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: payment.checkoutUrl.isEmpty
                  ? null
                  : () => _openCheckoutUrl(payment.checkoutUrl),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('M? l?i trang thanh to?n'),
            ),
            SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() {}),
              icon: Icon(Icons.refresh_rounded),
              label: Text('L?m m?i tr?ng th?i'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ch?n ph??ng th?c',
          style: TextStyle(
            color: AppColors.textBody,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 12),
        PaymentMethodCard(
          icon: Icons.qr_code_2_rounded,
          title: 'Thanh to?n qua payOS',
          subtitle:
              'M? checkoutUrl ?o backend t?o. Flutter kh?ng ch?a secret key payOS.',
          color: AppColors.primary,
          enabled: payment.canStartPayos && !_isCreatingPayosLink,
          onTap: () => _createPayosLink(payment),
        ),
        SizedBox(height: 12),
        PaymentMethodCard(
          icon: Icons.payments_rounded,
          title: 'Thanh to?n ti?n m?t t?i qu?y',
          subtitle:
              'Chuy?n sang ch? thanh to?n t?i qu?y. Nh?n vi?n v?n l? ngu?n x?c nh?n paid.',
          color: AppColors.success,
          enabled: payment.canChooseCash && !_isChoosingCash,
          onTap: () => _markPayAtCounter(payment),
        ),
      ],
    );
  }

  Future<void> _createPayosLink(PatientPaymentModel payment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isCreatingPayosLink = true);
    try {
      final checkoutUrl = await _repository.createPayosCheckoutLink(
        payment: payment,
        patientId: user.uid,
      );
      if (!mounted) return;
      await _openCheckoutUrl(checkoutUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sau khi thanh to?n, tr?ng th?i s? t? c?p nh?t trong app.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Kh?ng t?o ???c link payOS: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreatingPayosLink = false);
    }
  }

  Future<void> _markPayAtCounter(PatientPaymentModel payment) async {
    setState(() => _isChoosingCash = true);
    try {
      await _repository.markPayAtCounter(payment);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('?? chuy?n sang ch? thanh to?n t?i qu?y.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Kh?ng c?p nh?t ???c thanh to?n t?i qu?y: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isChoosingCash = false);
    }
  }

  Future<void> _openCheckoutUrl(String checkoutUrl) async {
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null) throw Exception('checkoutUrl kh?ng h?p l?.');

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) throw Exception('Kh?ng m? ???c trang thanh to?n payOS.');
  }

  void _notifyPaidOnce(PatientPaymentModel payment) {
    if (_successNotified || payment.status != 'paid') return;
    _successNotified = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Thanh to?n th?nh c?ng.'),
        ),
      );
    });
  }

  InvoiceModel _toInvoice(PatientPaymentModel payment) {
    return InvoiceModel(
      id: payment.invoiceId.isEmpty ? payment.id : payment.invoiceId,
      appointmentId: payment.appointmentId,
      patientId: payment.patientId,
      expenseType: payment.expenseType.isEmpty
          ? 'D?ch v? y t?'
          : payment.expenseType,
      serviceContent: payment.serviceContent.isEmpty
          ? 'Thanh to?n kh?m b?nh'
          : payment.serviceContent,
      doctorName: payment.doctorName,
      departmentName: payment.specialtyName,
      totalAmount: payment.totalAmount,
      discountAmount: payment.discountAmount,
      amount: payment.amount,
      status: payment.status,
      createdAt: payment.createdAt,
      paymentDate: payment.paidAt,
    );
  }
}

class _StatusHeader extends StatelessWidget {
  _StatusHeader({required this.payment});

  final PatientPaymentModel payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: PaymentStatusBadge.statusColor(
                payment.status,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              payment.status == 'paid'
                  ? Icons.check_circle_rounded
                  : Icons.receipt_long_rounded,
              color: PaymentStatusBadge.statusColor(payment.status),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PaymentStatusBadge.statusLabel(payment.status),
                  style: TextStyle(
                    color: AppColors.textBody,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${NumberFormat('#,###').format(payment.amount)} ?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          PaymentStatusBadge(status: payment.status),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.payment});

  final PatientPaymentModel payment;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Chi tiết chi phí',
      rows: [
        _InfoRow(
          'Tạm tính',
          '${NumberFormat('#,###').format(payment.totalAmount)} đ',
        ),
        _InfoRow(
          payment.insuranceApplied
              ? 'BHYT hỗ trợ ${payment.insuranceCoveragePercent}%'
              : 'BHYT hỗ trợ',
          '${NumberFormat('#,###').format(payment.insuranceCoveredAmount)} đ',
        ),
        if (payment.insuranceApplied) _InfoRow('Bảo hiểm', 'Đã áp ?ụng BHYT'),
        _InfoRow(
          'Bệnh nhân cần thanh toán',
          '${NumberFormat('#,###').format(payment.patientPayAmount == 0 ? payment.amount : payment.patientPayAmount)} đ',
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  _InfoCard({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textBody,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textBody,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
