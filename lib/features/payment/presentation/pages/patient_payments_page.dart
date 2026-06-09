import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../widgets/payment_empty_state.dart';
import '../widgets/payment_status_badge.dart';
import '../widgets/payment_summary_card.dart';

class PatientPaymentsPage extends StatefulWidget {
  const PatientPaymentsPage({super.key});

  @override
  State<PatientPaymentsPage> createState() => _PatientPaymentsPageState();
}

class _PatientPaymentsPageState extends State<PatientPaymentsPage> {
  final _repository = PatientPaymentRepositoryImpl();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập để xem thanh toán.')),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textBody,
          elevation: 0,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thanh toán',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 2),
              Text(
                'Theo dõi hóa đơn và lịch sử thanh toán của bạn.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            tabs: [
              Tab(text: 'Cần thanh toán'),
              Tab(text: 'Đang xử lý'),
              Tab(text: 'Đã thanh toán'),
              Tab(text: 'Tất cả'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: StreamBuilder<List<PatientPaymentModel>>(
          stream: _repository.watchPatientPayments(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return _PaymentListSkeleton();
            }

            if (snapshot.hasError) {
              return PaymentEmptyState(
                message: 'Không đọc được lịch sử thanh toán: ${snapshot.error}',
              );
            }

            final payments = snapshot.data ?? const <PatientPaymentModel>[];
            return Column(
              children: [
                PaymentSummaryCard(payments: payments),
                Expanded(
                  child: TabBarView(
                    children: [
                      _PaymentTab(
                        payments: payments.where(_needPayment).toList(),
                        emptyMessage:
                            'Chưa có hóa đơn cần thanh toán. Hóa đơn sẽ được tạo sau khi bạn hoàn tất khám.',
                      ),
                      _PaymentTab(
                        payments: payments.where(_processing).toList(),
                        emptyMessage: 'Chưa có thanh toán nào đang chờ xử lý.',
                      ),
                      _PaymentTab(
                        payments: payments
                            .where((payment) => payment.status == 'paid')
                            .toList(),
                        emptyMessage:
                            'Lịch sử đã thanh toán sẽ được cập nhật realtime.',
                      ),
                      _PaymentTab(
                        payments: payments,
                        emptyMessage:
                            'Khi có hóa đơn mới, bạn sẽ thấy tại đây.',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static bool _needPayment(PatientPaymentModel payment) {
    return const {
      'unpaid',
      'pending',
      'failed',
      'expired',
    }.contains(payment.status);
  }

  static bool _processing(PatientPaymentModel payment) {
    return const {
      'payos_pending',
      'qr_generated',
      'waiting_confirmation',
      'pay_at_counter',
    }.contains(payment.status);
  }
}

class _PaymentTab extends StatelessWidget {
  const _PaymentTab({required this.payments, required this.emptyMessage});

  final List<PatientPaymentModel> payments;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: payments.isEmpty
          ? ListView(children: [PaymentEmptyState(message: emptyMessage)])
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
              itemCount: payments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _PaymentCard(payment: payments[index]);
              },
            ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final PatientPaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final title = payment.doctorName.isNotEmpty
        ? payment.doctorName
        : (payment.specialtyName.isNotEmpty
              ? payment.specialtyName
              : 'Hóa đơn khám bệnh');
    final subtitle = payment.specialtyName.isNotEmpty
        ? payment.specialtyName
        : (payment.serviceContent.isNotEmpty
              ? payment.serviceContent
              : 'Dịch vụ y tế');
    final date = payment.appointmentDate ?? payment.createdAt;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.invoiceDetail,
        arguments: payment,
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textBody,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PaymentStatusBadge(status: payment.status),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniInfo(
                    label: 'Mã hóa đơn',
                    value: payment.paymentCode,
                  ),
                ),
                Expanded(
                  child: _MiniInfo(
                    label: 'Ngày khám',
                    value: DateFormat('dd/MM/yyyy').format(date),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${NumberFormat('#,###').format(payment.amount)} đ',
                  style: TextStyle(
                    color: AppColors.textBody,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.invoiceDetail,
                    arguments: payment,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: payment.status == 'paid'
                        ? AppColors.secondary
                        : AppColors.primary,
                    foregroundColor: payment.status == 'paid'
                        ? AppColors.textBody
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    payment.status == 'paid' ? 'Xem chi tiết' : 'Thanh toán',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textHint, fontSize: 11)),
        SizedBox(height: 3),
        Text(
          value.isEmpty ? '-' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textBody,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PaymentListSkeleton extends StatelessWidget {
  const _PaymentListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(20),
      itemCount: 5,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        height: 132,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
