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
              'Chi tiet thanh toan',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                tooltip: 'Lam moi trang thai',
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
                  _InfoRow('Ma hoa don', payment.paymentCode),
                  _InfoRow(
                    'Bac si',
                    payment.doctorName.isEmpty ? '-' : payment.doctorName,
                  ),
                  _InfoRow(
                    'Chuyen khoa',
                    payment.specialtyName.isEmpty ? '-' : payment.specialtyName,
                  ),
                  _InfoRow(
                    'Ngay kham',
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
              const SizedBox(height: 28),
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
            const Text(
              'Thanh toan thanh cong',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text('So tien: ${NumberFormat('#,###').format(payment.amount)} d'),
            if (payment.paidAt != null)
              Text(
                'Thoi gian: ${DateFormat('dd/MM/yyyy HH:mm').format(payment.paidAt!)}',
              ),
            if (payment.gatewayTransactionId.isNotEmpty)
              Text('Ma giao dich: ${payment.gatewayTransactionId}'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.digitalReceipt,
                arguments: _toInvoice(payment),
              ),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Xem bien nhan'),
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
            const Text(
              'Thanh toan tai quay',
              style: TextStyle(
                color: AppColors.textBody,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              payment.paymentCode,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui long dua ma hoa don nay cho nhan vien tai quay. Nhan vien se xac nhan da thanh toan sau khi thu tien.',
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
            const Text(
              'Dang cho thanh toan payOS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sau khi ban thanh toan, backend/webhook se cap nhat trang thai. App se tu doi sang thanh cong.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: payment.checkoutUrl.isEmpty
                  ? null
                  : () => _openCheckoutUrl(payment.checkoutUrl),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Mo lai trang thanh toan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Lam moi trang thai'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chon phuong thuc',
          style: TextStyle(
            color: AppColors.textBody,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        PaymentMethodCard(
          icon: Icons.qr_code_2_rounded,
          title: 'Thanh toan qua payOS',
          subtitle:
              'Mo checkoutUrl do backend tao. Flutter khong chua secret key payOS.',
          color: AppColors.primary,
          enabled: payment.canStartPayos && !_isCreatingPayosLink,
          onTap: () => _createPayosLink(payment),
        ),
        const SizedBox(height: 12),
        PaymentMethodCard(
          icon: Icons.payments_rounded,
          title: 'Thanh toan tien mat tai quay',
          subtitle:
              'Chuyen sang cho thanh toan tai quay. Nhan vien van la nguon xac nhan paid.',
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
        const SnackBar(
          content: Text(
            'Sau khi thanh toan, trang thai se tu cap nhat trong app.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Khong tao duoc link payOS: $e'),
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
        const SnackBar(
          content: Text('Da chuyen sang cho thanh toan tai quay.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Khong cap nhat duoc thanh toan tai quay: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isChoosingCash = false);
    }
  }

  Future<void> _openCheckoutUrl(String checkoutUrl) async {
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null) throw Exception('checkoutUrl khong hop le.');

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) throw Exception('Khong mo duoc trang thanh toan payOS.');
  }

  void _notifyPaidOnce(PatientPaymentModel payment) {
    if (_successNotified || payment.status != 'paid') return;
    _successNotified = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Thanh toan thanh cong.'),
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
          ? 'Dich vu y te'
          : payment.expenseType,
      serviceContent: payment.serviceContent.isEmpty
          ? 'Thanh toan kham benh'
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
  const _StatusHeader({required this.payment});

  final PatientPaymentModel payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PaymentStatusBadge.statusLabel(payment.status),
                  style: const TextStyle(
                    color: AppColors.textBody,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat('#,###').format(payment.amount)} d',
                  style: const TextStyle(
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
      title: 'Chi tiet chi phi',
      rows: [
        _InfoRow(
          'Tong tien',
          '${NumberFormat('#,###').format(payment.totalAmount)} d',
        ),
        _InfoRow(
          'Giam tru',
          '${NumberFormat('#,###').format(payment.discountAmount)} d',
        ),
        _InfoRow(
          'Can thanh toan',
          '${NumberFormat('#,###').format(payment.amount)} d',
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

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
            style: const TextStyle(
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
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
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
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
