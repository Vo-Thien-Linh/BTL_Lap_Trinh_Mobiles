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
              'Chi tiết thanh toán',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                tooltip: 'Làm mới trạng thái',
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
                title: 'Thông tin cuộc hẹn',
                rows: [
                  _InfoRow('Mã thanh toán', payment.paymentCode),
                  if (payment.invoiceCode.isNotEmpty &&
                      payment.invoiceCode != payment.paymentCode)
                    _InfoRow('Mã hóa đơn', payment.invoiceCode),
                  _InfoRow(
                    'Bác sĩ',
                    payment.doctorName.isEmpty ? '-' : payment.doctorName,
                  ),
                  _InfoRow(
                    'Chuyên khoa',
                    payment.specialtyName.isEmpty ? '-' : payment.specialtyName,
                  ),
                  _InfoRow(
                    'Ngày khám',
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
              'Thanh toán thành công',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text('Số tiền: ${NumberFormat('#,###').format(payment.amount)} đ'),
            if (payment.paidAt != null)
              Text(
                'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(payment.paidAt!)}',
              ),
            if (payment.gatewayTransactionId.isNotEmpty)
              Text('Mã giao dịch: ${payment.gatewayTransactionId}'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.digitalReceipt,
                arguments: _toInvoice(payment),
              ),
              icon: Icon(Icons.receipt_long_rounded),
              label: Text('Xem biên nhận'),
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
              'Thanh toán tại quầy',
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
              'Vui lòng đưa mã hóa đơn này cho nhân viên tại quầy. Nhân viên sẽ xác nhận đã thanh toán sau khi thu tiền.',
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
              'Đang chờ thanh toán payOS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'Sau khi bạn thanh toán, backend/webhook sẽ cập nhật trạng thái. App sẽ tự đổi sang thành công.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: payment.checkoutUrl.isEmpty
                  ? null
                  : () => _openCheckoutUrl(payment.checkoutUrl),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Mở lại trang thanh toán'),
            ),
            SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() {}),
              icon: Icon(Icons.refresh_rounded),
              label: Text('Làm mới trạng thái'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn phương thức',
          style: TextStyle(
            color: AppColors.textBody,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 12),
        PaymentMethodCard(
          icon: Icons.qr_code_2_rounded,
          title: 'Thanh toán qua payOS',
          subtitle:
              'Mở trang thanh toán do backend tạo. Flutter không chứa secret key payOS.',
          color: AppColors.primary,
          enabled: payment.canStartPayos && !_isCreatingPayosLink,
          onTap: () => _createPayosLink(payment),
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
            'Sau khi thanh toán, trạng thái sẽ tự cập nhật trong app.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Không tạo được link payOS: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreatingPayosLink = false);
    }
  }

  Future<void> _openCheckoutUrl(String checkoutUrl) async {
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null) throw Exception('checkoutUrl không hợp lệ.');

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) throw Exception('Không mở được trang thanh toán payOS.');
  }

  void _notifyPaidOnce(PatientPaymentModel payment) {
    if (_successNotified || payment.status != 'paid') return;
    _successNotified = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Thanh toán thành công.'),
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
          ? 'Dịch vụ y tế'
          : payment.expenseType,
      serviceContent: payment.serviceContent.isEmpty
          ? 'Thanh toán khám bệnh'
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
                  '${NumberFormat('#,###').format(payment.amount)} đ',
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
        if (payment.insuranceApplied) _InfoRow('Bảo hiểm', 'Đã áp dụng BHYT'),
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
