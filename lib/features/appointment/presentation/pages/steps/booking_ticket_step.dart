import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:baitaplon/features/appointment/presentation/bloc/booking_bloc.dart';
import 'package:baitaplon/features/appointment/domain/entities/appointment_entities.dart';
import 'package:baitaplon/app/theme/app_colors.dart';
import 'package:baitaplon/shared/widgets/custom_button.dart';

class BookingTicketStep extends StatelessWidget {
  const BookingTicketStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final appointment = state.createdAppointment;
        if (appointment == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
              const SizedBox(height: 12),
              const Text(
                'ĐẶT LỊCH THÀNH CÔNG!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              _buildTicket(context, appointment),
              const SizedBox(height: 32),
              CustomButton(
                text: 'XÁC NHẬN & VỀ TRANG CHỦ',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: 48), // Bottom safe space
            ],
          ),
        );
      },
    );
  }

  Widget _buildTicket(BuildContext context, HospitalAppointment appointment) {
    final formattedFee = NumberFormat.decimalPattern().format(appointment.consultationFee);
    final dateStr = DateFormat('dd/MM/yyyy').format(appointment.appointmentDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const Text(
                  'Bệnh viện Đa khoa MedCare',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '123 Đường Số 1, Phường Bến Nghé, Quận 1, TP. HCM',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.hint),
                ),
                const Divider(height: 30, color: AppColors.border),
                const Text(
                  'PHIẾU KHÁM BỆNH',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã phiếu: APP${DateFormat('yyyyMMdd').format(appointment.createdAt)}${appointment.queueNumber.toString().padLeft(3, '0')}',
                  style: TextStyle(fontSize: 11, color: AppColors.hint),
                ),
              ],
            ),
          ),
          
          // Department & Room
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              children: [
                Text(
                  appointment.departmentName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appointment.roomNumber,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // STT
          _buildSTTCircle(appointment.queueNumber),
          
          const SizedBox(height: 20),
          
          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildTicketRow('Họ tên:', appointment.patientName.toUpperCase()),
                _buildTicketRow('Mã BN:', 'BN-${appointment.patientId.substring(0, 6)}'),
                _buildTicketRow('Ngày khám:', dateStr),
                _buildTicketRow('Đối tượng:', appointment.insuranceNumber != null ? 'BHYT (${appointment.insuranceNumber})' : 'Không BHYT'),
                _buildTicketRow('Tiền khám:', '$formattedFee đ', valColor: AppColors.success),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Footer / Cut effect
          _buildTicketFooter(appointment),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSTTCircle(int number) {
    return Column(
      children: [
        const Text(
          'SỐ THỨ TỰ',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.hint),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success, width: 3),
          ),
          child: Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.success,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketRow(String label, String value, {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.hint)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valColor ?? AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketFooter(HospitalAppointment appointment) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.hint),
              const SizedBox(width: 8),
              Text(
                'Lưu ý quan trọng',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.hint),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Vui lòng có mặt tại phòng khám 15 phút trước giờ hẹn. Phiếu khám chỉ có giá trị trong ngày và không có giá trị thay thế đơn thuốc.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.text,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
