import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../app/routes/app_routes.dart';
import '../../bloc/booking_bloc.dart';
import '../../../domain/entities/appointment_entities.dart';

class BookingTicketStep extends StatelessWidget {
  const BookingTicketStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final appointment = state.createdAppointment;
        if (appointment == null) return const SizedBox.shrink();

        final isConfirmed = appointment.status == 'confirmed';

        return Theme(
          data: Theme.of(context).copyWith(
            dividerTheme: const DividerThemeData(thickness: 1, color: Color(0xFFE2E8F0)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                if (!isConfirmed) ...[
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'XÁC NHẬN PHIẾU KHÁM',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vui lòng kiểm tra lại thông tin trước khi thanh toán',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ] else ...[
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'THANH TOÁN THÀNH CÔNG!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF065F46), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cảm ơn bạn đã tin tưởng dịch vụ của MedCare',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(height: 32),
                _buildExaminationSlip(context, appointment),
                const SizedBox(height: 24),
                
                if (!isConfirmed) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<BookingBloc>().add(FinalizePaymentAndConfirm(
                          appointmentId: appointment.id,
                          patientId: appointment.patientId,
                          amount: appointment.consultationFee,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: state.status == BookingStatus.loading 
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('XÁC NHẬN THANH TOÁN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
                    child: const Text(
                      'Thay đổi thông tin cá nhân',
                      style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('XONG & VỀ TRANG CHỦ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExaminationSlip(BuildContext context, HospitalAppointment appointment) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HỆ THỐNG Y TẾ MEDCARE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                          Text('CƠ SỞ: 123 Bế Văn Đàn, TP. HCM', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(8)),
                      child: const Text('MEDCARE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                const Text('PHIẾU KHÁM BỆNH', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 1.5)),
                Text(
                  'Mã phiếu: ${appointment.id.toUpperCase().substring(0, 8)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),

          // Main Info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Info Section
                _buildSectionTitle('THÔNG TIN BỆNH NHÂN'),
                const SizedBox(height: 12),
                _buildInfoRow('Họ và tên:', appointment.patientName.toUpperCase(), isBold: true),
                _buildInfoRow('Mã bệnh nhân:', appointment.patientId.substring(0, 10).toUpperCase()),
                _buildInfoRow('Ngày sinh:', appointment.patientDOB ?? 'Chưa cập nhật'),
                _buildInfoRow('Giới tính:', appointment.patientGender ?? 'Chưa cập nhật'),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: DottedLine(),
                ),

                // Appointment Section
                _buildSectionTitle('CHI TIẾT LỊCH HẸN'),
                const SizedBox(height: 12),
                _buildInfoRow('Chuyên khoa:', appointment.departmentName),
                _buildInfoRow('Vị trí:', appointment.roomNumber, valColor: const Color(0xFF2563EB)),
                _buildInfoRow('Ngày khám:', DateFormat('dd/MM/yyyy').format(appointment.appointmentDate)),
                _buildInfoRow('Giờ dự kiến:', appointment.timeSlot, isBold: true),
                
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      const Text('SỐ THỨ TỰ KHÁM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Container(
                        width: 90, height: 90,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF312E81), width: 3),
                        ),
                        child: Text(
                          appointment.queueNumber.toString(),
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF312E81)),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: DottedLine(),
                ),

                // Payment Section
                _buildSectionTitle('THANH TOÁN'),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Đối tượng:', 
                  appointment.insuranceNumber != null ? 'BẢO HIỂM Y TẾ' : 'KHÁM DỊCH VỤ',
                  valColor: appointment.insuranceNumber != null ? const Color(0xFF059669) : const Color(0xFFD97706),
                ),
                if (appointment.insuranceNumber != null)
                  _buildInfoRow('Mã thẻ BHYT:', appointment.insuranceNumber!),
                _buildInfoRow(
                  'Chi phí khám:', 
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(appointment.consultationFee),
                  valSize: 18, isBold: true, valColor: const Color(0xFFB91C1C),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7ED),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time_filled_rounded, color: Color(0xFFC2410C), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vui lòng có mặt tại quầy tiếp đón 15 phút trước giờ hẹn để chuẩn bị thủ tục.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9A3412), fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF334155), letterSpacing: 1));
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valColor, double valSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontSize: valSize,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: valColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class DottedLine extends StatelessWidget {
  const DottedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(width: dashWidth, height: 1, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFCBD5E1))));
          }),
        );
      },
    );
  }
}
