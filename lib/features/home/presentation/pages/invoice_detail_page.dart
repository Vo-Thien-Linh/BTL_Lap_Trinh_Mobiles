import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../appointment/presentation/payment_management_bloc/payment_bloc.dart';
import '../../../appointment/data/models/invoice_models.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class InvoiceDetailPage extends StatefulWidget {
  final InvoiceModel invoice;
  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  String _selectedPaymentMethod = 'Chuyển khoản';
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'label': 'Chuyển khoản',
      'icon': Icons.account_balance_rounded,
      'color': AppColors.primary,
      'bank': 'Vietcombank',
      'accNum': '1234567890',
      'accName': 'BV ĐA KHOA QUỐC TẾ',
    },
    {
      'label': 'Thẻ tín dụng',
      'icon': Icons.credit_card_rounded,
      'color': const Color(0xFF8B5CF6),
      'bank': 'Visa / Mastercard',
      'accNum': 'N/A',
      'accName': 'Thanh toán trực tuyến',
    },
    {
      'label': 'Ví điện tử',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFF10B981),
      'bank': 'MoMo / ZaloPay',
      'accNum': '0987654321',
      'accName': 'CÔNG TY CP BỆNH VIỆN',
    },
  ];

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Đã sao chép $label'),
          ],
        ),
        backgroundColor: AppColors.textBody,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = widget.invoice.status == 'paid';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textBody, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CHI TIẾT HÓA ĐƠN',
          style: TextStyle(
            color: AppColors.textBody,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state.status == PaymentStatus.success && isPaid == false) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.paymentSuccess,
              arguments: widget.invoice,
            );
          } else if (state.status == PaymentStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Thanh toán thất bại'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainInfoSection(),
              const SizedBox(height: 24),
              _buildPriceSection(),
              const SizedBox(height: 24),
              if (!isPaid) _buildPaymentMethodSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isPaid ? null : _buildBottomActions(),
    );
  }

  Widget _buildMainInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBody.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.receipt_long_rounded, 'Số hóa đơn', widget.invoice.id, highlight: true),
          const Divider(height: 32, color: AppColors.border),
          _buildInfoRow(Icons.calendar_today_rounded, 'Ngày', DateFormat('dd/MM/yyyy').format(widget.invoice.createdAt)),
          _buildInfoRow(Icons.category_outlined, 'Loại', widget.invoice.expenseType),
          _buildInfoRow(Icons.search_rounded, 'Nội dung', widget.invoice.serviceContent),
          _buildInfoRow(Icons.business_rounded, 'Khoa', widget.invoice.departmentName ?? 'N/A'),
          _buildInfoRow(Icons.person_outline_rounded, 'Bác sĩ', widget.invoice.doctorName ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: highlight ? AppColors.primary : AppColors.textBody,
                    fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.primary,
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceRow('Tổng tiền ban đầu', widget.invoice.totalAmount, Colors.white70),
          const SizedBox(height: 12),
          _buildPriceRow('Giảm giá / BHYT', widget.invoice.discountAmount, Colors.white70, isNegative: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: Colors.white12),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thành tiền',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '${NumberFormat('#,###').format(widget.invoice.amount)} đ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, Color color, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(
          '${isNegative ? "- " : ""}${NumberFormat('#,###').format(value)} đ',
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn phương thức thanh toán',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textBody),
        ),
        const SizedBox(height: 16),
        ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)).toList(),
      ],
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    bool isSelected = _selectedPaymentMethod == method['label'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? method['color'].withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? method['color'] : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
             ? [BoxShadow(color: method['color'].withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] 
             : null,
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _selectedPaymentMethod = method['label']),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? method['color'] : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        method['icon'],
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        method['label'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: method['color'], size: 24),
                  ],
                ),
              ),
            ),
            if (isSelected) _buildExpandedMethodDetails(method),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedMethodDetails(Map<String, dynamic> method) {
    final transferContent = 'THANH TOAN HD ${widget.invoice.id}';
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 20),
          // QR Code Simulation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage('https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=PREMIUM_HOSPITAL_PAYMENT'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Quét mã QR để thanh toán nhanh',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Account Info
          _buildCopyableInfoRow('Ngân hàng', method['bank'], copyable: false),
          _buildCopyableInfoRow('Số tài khoản', method['accNum']),
          _buildCopyableInfoRow('Chủ tài khoản', method['accName'], copyable: false),
          _buildCopyableInfoRow('Nội dung', transferContent),
          
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đang chuyển hướng sang ứng dụng ${method['label']}...'),
                        backgroundColor: AppColors.primary,
                      )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: method['color'],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mở ứng dụng ${method['label'].split(' ').last}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCopyableInfoRow(String label, String value, {bool copyable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(color: AppColors.textBody, fontWeight: FontWeight.w900, fontSize: 13),
              ),
              if (copyable && value != 'N/A')
                IconButton(
                  onPressed: () => _copyToClipboard(value, label),
                  icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                  padding: const EdgeInsets.only(left: 8),
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Đóng',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                context.read<PaymentBloc>().add(ProcessPayment(
                  invoiceId: widget.invoice.id,
                  appointmentId: widget.invoice.appointmentId,
                  patientId: FirebaseAuth.instance.currentUser!.uid,
                  amount: widget.invoice.amount,
                  paymentMethod: _selectedPaymentMethod,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('XÁC NHẬN THANH TOÁN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
