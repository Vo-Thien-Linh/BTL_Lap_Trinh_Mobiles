import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../appointment/data/models/invoice_models.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/app_routes.dart';

class PaymentSuccessPage extends StatelessWidget {
  final InvoiceModel invoice;
  const PaymentSuccessPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            _buildCelebrationHeader(),
            const SizedBox(height: 32),
            _buildReceiptCard(),
            const Spacer(),
            _buildActionButtons(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'THANH TOÁN THÀNH CÔNG',
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w900, 
            color: AppColors.textBody, 
            letterSpacing: 1.2
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Hóa đơn đã được xác thực và xử lý trực tuyến',
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w600, 
            color: AppColors.textSecondary
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBody.withOpacity(0.04), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _buildReceiptRow('Mã giao dịch', '#${invoice.id.toUpperCase()}', isHighlight: true),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: AppColors.border)),
          _buildReceiptRow('Nội dung', invoice.serviceContent),
          const SizedBox(height: 12),
          _buildReceiptRow('Loại chi phí', invoice.expenseType),
          const SizedBox(height: 12),
          _buildReceiptRow('Ngày thanh toán', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
          const SizedBox(height: 12),
          _buildReceiptRow('Phương thức', 'Ví điện tử / Thẻ'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: AppColors.border)),
          _buildReceiptRow(
            'Tổng thanh toán', 
            '${NumberFormat('#,###').format(invoice.amount)} đ', 
            isHighlight: true, 
            largeValue: true
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background, 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2_rounded, size: 24, color: AppColors.textHint),
                SizedBox(width: 12),
                Text(
                  'KÝ SỐ BỞI HỆ THỐNG Y TẾ v4.0 (SECURE)',
                  style: TextStyle(
                    fontSize: 8, 
                    fontWeight: FontWeight.w900, 
                    color: AppColors.textHint, 
                    letterSpacing: 0.8
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isHighlight = false, bool largeValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        Text(
          value,
          style: TextStyle(
            fontSize: largeValue ? 20 : 13,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
            color: isHighlight && largeValue ? AppColors.primary : AppColors.textBody,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context, 
                AppRoutes.digitalReceipt,
                arguments: invoice,
              );
            },
            icon: const Icon(Icons.receipt_long_rounded, size: 20),
            label: const Text('XEM & IN BIÊN LAI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('TRỞ VỀ TRANG CHỦ', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 14, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}
