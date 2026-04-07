import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:baitaplon/features/appointment/presentation/bloc/booking_bloc.dart';
import 'package:baitaplon/app/theme/app_colors.dart';
import 'package:baitaplon/shared/widgets/custom_button.dart';

class BookingSummaryStep extends StatefulWidget {
  const BookingSummaryStep({super.key});

  @override
  State<BookingSummaryStep> createState() => _BookingSummaryStepState();
}

class _BookingSummaryStepState extends State<BookingSummaryStep> {
  final TextEditingController _symptomsController = TextEditingController();

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final fee = state.selectedDoctor?.consultationFee ?? 0;
        final formattedFee = NumberFormat.decimalPattern().format(fee);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.read<BookingBloc>().add(StepBack()),
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                  ),
                  const Text(
                    'Xác nhận thông tin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSummaryCard(state),
              const SizedBox(height: 24),
              const Text(
                'Triệu chứng / Lý do khám',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _symptomsController,
                maxLines: 3,
                onChanged: (val) => context.read<BookingBloc>().add(UpdateSymptoms(val)),
                decoration: InputDecoration(
                  hintText: 'Mô tả ngắn gọn tình trạng sức khỏe của bạn...',
                  hintStyle: const TextStyle(fontSize: 14, color: AppColors.hint),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Phương thức thanh toán',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  _buildPaymentSelector(context, state),
                ],
              ),
              const SizedBox(height: 24),
              _buildFeeRow('Tiền khám', '$formattedFee đ'),
              _buildFeeRow('Dịch vụ', '0 đ'),
              const Divider(height: 32, thickness: 1, color: AppColors.border),
              _buildFeeRow('TỔNG THANH TOÁN', '$formattedFee đ', isTotal: true),
              const SizedBox(height: 24),
              if (state.selectedPaymentMethod != 'CASH') _buildPaymentQRSection(state, formattedFee),
              const SizedBox(height: 20),
              CustomButton(
                text: 'XÁC NHẬN ĐẶT LỊCH',
                isLoading: state.status == BookingStatus.loading,
                onPressed: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    context.read<BookingBloc>().add(
                          ConfirmBooking(
                            patientId: user.uid,
                            patientName: user.displayName ?? 'Người bệnh',
                          ),
                        );
                  }
                },
              ),
              const SizedBox(height: 40), // Increased bottom padding
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BookingState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            Icons.local_hospital_rounded,
            'Chuyên khoa',
            state.selectedDepartment?.name ?? '-',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.person_rounded,
            'Bác sĩ',
            state.selectedDoctor?.name ?? '-',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.calendar_month_rounded,
            'Ngày khám',
            state.selectedDate != null ? DateFormat('dd/MM/yyyy').format(state.selectedDate!) : '-',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.access_time_filled_rounded,
            'Giờ khám (Dự kiến)',
            state.selectedShift != null ? 'Ca ${state.selectedShift!.name} (${state.selectedShift!.startTime})' : '-',
          ),
          if (state.selectedQueueNumber != null) ...[
            const Divider(height: 24),
            _buildSummaryRow(
              Icons.format_list_numbered_rounded,
              'Số thứ tự (STT)',
              'Số ${state.selectedQueueNumber}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.hint),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSelector(BuildContext context, BookingState state) {
    final Map<String, Map<String, dynamic>> methodMap = {
      'CASH': {'name': 'Tiền mặt', 'icon': Icons.payments_rounded, 'color': Colors.green},
      'BANK': {'name': 'Chuyển khoản', 'icon': Icons.account_balance_rounded, 'color': Colors.blue},
      'WALLET': {'name': 'Ví điện tử', 'icon': Icons.account_balance_wallet_rounded, 'color': Colors.purple},
    };

    final currentMethod = methodMap[state.selectedPaymentMethod] ?? methodMap['CASH']!;

    return GestureDetector(
      onTap: () => _showPaymentSelectionBottomSheet(context, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (currentMethod['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: currentMethod['color'] as Color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(currentMethod['icon'] as IconData, color: currentMethod['color'] as Color, size: 18),
            const SizedBox(width: 8),
            Text(
              currentMethod['name'] as String,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: currentMethod['color'] as Color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: currentMethod['color'] as Color, size: 18),
          ],
        ),
      ),
    );
  }

  void _showPaymentSelectionBottomSheet(BuildContext context, BookingState state) {
    final options = [
      {'id': 'CASH', 'name': 'Tiền mặt', 'icon': Icons.payments_rounded, 'color': Colors.green, 'desc': 'Thanh toán trực tiếp tại bệnh viện'},
      {'id': 'BANK', 'name': 'Chuyển khoản', 'icon': Icons.account_balance_rounded, 'color': Colors.blue, 'desc': 'Chuyển khoản qua số tài khoản ngân hàng'},
      {'id': 'WALLET', 'name': 'Ví điện tử', 'icon': Icons.account_balance_wallet_rounded, 'color': Colors.purple, 'desc': 'Thanh toán qua ví Momo / ZaloPay'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn phương thức thanh toán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 20),
              ...options.map((opt) {
                final isSelected = state.selectedPaymentMethod == opt['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? (opt['color'] as Color).withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? (opt['color'] as Color) : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (opt['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(opt['icon'] as IconData, color: opt['color'] as Color, size: 24),
                    ),
                    title: Text(
                      opt['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      opt['desc'] as String,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isSelected ? Icon(Icons.check_circle_rounded, color: opt['color'] as Color) : null,
                    onTap: () {
                      context.read<BookingBloc>().add(SelectPaymentMethod(opt['id'] as String));
                      Navigator.pop(sheetContext);
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentQRSection(BookingState state, String amount) {
    final isBank = state.selectedPaymentMethod == 'BANK';
    final qrPath = isBank
        ? r'C:\Users\84329\.gemini\antigravity\brain\0c1b7fb5-716f-4e29-9434-26641698169f\bank_transfer_qr_mockup_1775484771136.png'
        : r'C:\Users\84329\.gemini\antigravity\brain\0c1b7fb5-716f-4e29-9434-26641698169f\momo_qr_mockup_1775484796009.png';
    
    final color = isBank ? Colors.blue : Colors.purple;
    final providerName = isBank ? 'Ngân hàng (VietinBank)' : 'Ví điện tử (Momo)';
    final patientName = FirebaseAuth.instance.currentUser?.displayName ?? 'NGƯỜI BỆNH';
    final note = 'THANH TOAN $patientName STT ${state.selectedQueueNumber ?? ""}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                'Mã QR Thanh toán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isBank ? Colors.blue.shade800 : Colors.purple.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(qrPath),
                width: 180,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 180,
                  height: 180,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            providerName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildQRInfoRow('Số tiền:', '$amount đ', color),
          _buildQRInfoRow('Nội dung:', note.toUpperCase(), color),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, color: color, size: 14),
                const SizedBox(width: 8),
                const Text(
                  'Vui lòng quét mã và thanh toán trước khi xác nhận',
                  style: TextStyle(fontSize: 11, color: AppColors.hint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRInfoRow(String label, String value, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.hint),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: themeColor == Colors.blue ? Colors.blue.shade900 : Colors.purple.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isTotal ? AppColors.text : AppColors.hint,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 15,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primaryDark : AppColors.text,
          ),
        ),
      ],
    );
  }
}
