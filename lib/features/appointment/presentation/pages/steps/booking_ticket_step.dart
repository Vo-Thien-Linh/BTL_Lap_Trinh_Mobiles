import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

        return Theme(
          data: Theme.of(context).copyWith(
            dividerTheme: const DividerThemeData(
              thickness: 1,
              color: Color(0xFFE2E8F0),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 54,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đặt lịch thành công',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Phiếu khám đã được tạo. Bạn sẽ thanh toán sau khi có hóa đơn từ bác sĩ hoặc nhân viên.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                _buildExaminationSlip(appointment),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Xong & về trang chủ'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExaminationSlip(HospitalAppointment appointment) {
    final expectedTime = _estimatedTimeRange(appointment);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
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
                          Text(
                            'BỆNH VIỆN LPHV',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          Text(
                            'Phiếu xác nhận lịch khám',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LPHV',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'PHIẾU KHÁM BỆNH',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Mã phiếu: ${_displayCode(appointment.appointmentCode, appointment.id)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('THÔNG TIN BỆNH NHÂN'),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Họ và tên:',
                  appointment.patientName.toUpperCase(),
                  isBold: true,
                ),
                _buildInfoRow(
                  'Mã bệnh nhân:',
                  _displayCode(appointment.patientCode, appointment.patientId),
                ),
                _buildInfoRow(
                  'Ngày sinh:',
                  appointment.patientDOB ?? 'Chưa cập nhật',
                ),
                _buildInfoRow(
                  'Giới tính:',
                  appointment.patientGender ?? 'Chưa cập nhật',
                ),
                if (appointment.insuranceNumber != null &&
                    appointment.insuranceNumber!.trim().isNotEmpty)
                  _buildInfoRow('Mã thẻ BHYT:', appointment.insuranceNumber!),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: DottedLine(),
                ),
                _buildSectionTitle('CHI TIẾT LỊCH HẸN'),
                const SizedBox(height: 12),
                _buildInfoRow('Chuyên khoa:', appointment.departmentName),
                _buildInfoRow('Bác sĩ:', appointment.doctorName),
                _buildInfoRow(
                  'Phòng:',
                  appointment.roomNumber.trim().isEmpty
                      ? '-'
                      : appointment.roomNumber,
                  valColor: const Color(0xFF2563EB),
                ),
                _buildInfoRow(
                  'Ngày khám:',
                  DateFormat('dd/MM/yyyy').format(appointment.appointmentDate),
                ),
                _buildInfoRow('Buổi khám:', _shiftName(appointment.shiftId)),
                _buildInfoRow(
                  'STT khám:',
                  appointment.queueNumber.toString(),
                  isBold: true,
                ),
                _buildInfoRow(
                  'Thời gian khám dự kiến:',
                  expectedTime,
                  isBold: true,
                  valColor: const Color(0xFF2563EB),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: DottedLine(),
                ),
                _buildSectionTitle('THANH TOÁN'),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Trạng thái:',
                  'Thanh toán sau khi có hóa đơn',
                  valColor: const Color(0xFFD97706),
                  isBold: true,
                ),
                _buildInfoRow(
                  'Phí khám dự kiến:',
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: 'đ',
                    decimalDigits: 0,
                  ).format(appointment.consultationFee),
                  isBold: true,
                  valColor: const Color(0xFFB91C1C),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7ED),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  color: Color(0xFFC2410C),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vui lòng có mặt sớm hơn khoảng 30 phút để chuẩn bị thủ tục.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A3412),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
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
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Color(0xFF334155),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valColor,
    double valSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valColor ?? const Color(0xFF0F172A),
                fontSize: valSize,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _displayCode(String primary, String fallback) {
    final value = primary.trim().isNotEmpty ? primary.trim() : fallback.trim();
    if (value.length <= 12) return value.toUpperCase();
    return '${value.substring(0, 6).toUpperCase()}...${value.substring(value.length - 4).toUpperCase()}';
  }

  String _shiftName(String shiftId) {
    switch (shiftId.trim().toLowerCase()) {
      case 'morning':
        return 'Sáng';
      case 'afternoon':
        return 'Chiều';
      default:
        return shiftId.isEmpty ? '-' : shiftId;
    }
  }

  String _estimatedTimeRange(HospitalAppointment appointment) {
    final defaults = _defaultShiftTime(appointment.shiftId);
    final realSlot = _isRealTime(appointment.timeSlot)
        ? appointment.timeSlot.trim()
        : '';
    final startText = realSlot.isNotEmpty ? realSlot : defaults.start;
    final start = _timeOnDate(startText);
    final end = _timeOnDate(defaults.end);
    final shiftStart = _timeOnDate(defaults.start) ?? start;
    if (start == null ||
        end == null ||
        shiftStart == null ||
        !end.isAfter(shiftStart)) {
      return startText;
    }

    final queueNumber = appointment.queueNumber <= 0
        ? 1
        : appointment.queueNumber;
    final slotMinutes =
        end.difference(shiftStart).inMinutes / defaults.slotCount;
    final slotStart = realSlot.isNotEmpty
        ? start
        : shiftStart.add(
            Duration(minutes: ((queueNumber - 1) * slotMinutes).round()),
          );
    final slotEnd = slotStart.add(Duration(minutes: slotMinutes.round()));
    return '${DateFormat('HH:mm').format(slotStart)} - ${DateFormat('HH:mm').format(slotEnd)}';
  }

  bool _isRealTime(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed != '00:00' && trimmed != '00:00:00';
  }

  ({String start, String end, int slotCount}) _defaultShiftTime(
    String shiftId,
  ) {
    switch (shiftId.trim().toLowerCase()) {
      case 'afternoon':
        return (start: '13:30', end: '17:00', slotCount: 10);
      case 'morning':
      default:
        return (start: '07:30', end: '11:30', slotCount: 10);
    }
  }

  DateTime? _timeOnDate(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}

class DottedLine extends StatelessWidget {
  const DottedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 10).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => const SizedBox(
              width: 5,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        );
      },
    );
  }
}
