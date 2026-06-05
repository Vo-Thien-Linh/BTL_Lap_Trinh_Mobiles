import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/appointment_models.dart';

class PatientAppointmentDetailPage extends StatelessWidget {
  final String appointmentId;

  const PatientAppointmentDetailPage({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text(
          'Chi tiết lịch hẹn',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF15233D),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF15233D),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Appointments')
            .doc(appointmentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Không tìm thấy thông tin lịch hẹn',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final appointment = HospitalAppointmentModel.fromFirestore(
            snapshot.data!,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusBanner(appointment.effectiveStatus),
                SizedBox(height: 16),
                _buildDoctorInfo(appointment),
                SizedBox(height: 16),
                _buildTimeLocationCard(appointment),
                SizedBox(height: 16),
                _buildPatientInfoCard(appointment),
                SizedBox(height: 24),
                if (appointment.effectiveStatus == 'scheduled' ||
                    appointment.effectiveStatus == 'pending' ||
                    appointment.effectiveStatus == 'confirmed' ||
                    appointment.effectiveStatus == 'cancel_requested')
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to management page if not already there
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'QUẢN LÝ LỊCH HẸN',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                if (appointment.effectiveStatus == 'completed')
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.examinationDetail,
                        arguments: appointment,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'XEM KẾT QUẢ KHÁM',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case 'completed':
        bgColor = const Color(0xFFDEF7ED);
        textColor = const Color(0xFF0E9F6E);
        text = 'Đã hoàn tất';
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFDE8E8);
        textColor = const Color(0xFFE02424);
        text = 'Đã hủy';
        icon = Icons.cancel_rounded;
        break;
      case 'no_show':
      case 'absent':
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFC2410C);
        text = 'Vắng mặt';
        icon = Icons.person_off_rounded;
        break;
      case 'in_progress':
      case 'arrived':
      case 'calling':
      case 'ongoing':
        bgColor = const Color(0xFFE1EFFE);
        textColor = const Color(0xFF1A56DB);
        text = 'Đang khám';
        icon = Icons.sync_rounded;
        break;
      case 'confirmed':
        bgColor = const Color(0xFFE0F2FE);
        textColor = const Color(0xFF0369A1);
        text = 'Đã đặt lịch';
        icon = Icons.event_available_rounded;
        break;
      case 'cancel_requested':
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFC2410C);
        text = 'Chờ duyệt hủy';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'pending':
      case 'scheduled':
      default:
        bgColor = const Color(0xFFFEF08A);
        textColor = const Color(0xFF9CA3AF).withOpacity(0.0); // Reset
        textColor = const Color(0xFFB45309);
        text = 'Sắp tới';
        icon = Icons.access_time_filled_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorInfo(HospitalAppointmentModel appointment) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF15233D),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  appointment.departmentName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLocationCard(HospitalAppointmentModel appointment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_month_rounded,
            'Ngày khám',
            DateFormat('dd/MM/yyyy').format(appointment.appointmentDate),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          _buildInfoRow(
            Icons.access_time_rounded,
            'Thời gian khám dự kiến',
            _estimatedTimeRange(appointment),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          _buildInfoRow(
            Icons.pin_drop_rounded,
            'Phòng khám',
            appointment.roomNumber.isNotEmpty
                ? appointment.roomNumber
                : 'Chờ phân phòng',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          _buildInfoRow(
            Icons.format_list_numbered_rounded,
            'Số thứ tự',
            appointment.queueNumber > 0
                ? appointment.queueNumber.toString()
                : '---',
          ),
          const SizedBox(height: 14),
          _buildArrivalNote(),
        ],
      ),
    );
  }

  Widget _buildArrivalNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Text(
        'Bạn nên đến sớm hơn khoảng 30 phút để đảm bảo việc khám diễn ra thuận lợi.',
        style: TextStyle(
          color: Color(0xFF9A3412),
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }

  String _estimatedTimeRange(HospitalAppointmentModel appointment) {
    final defaults = _defaultShiftTime(appointment.shiftId);
    final startText = appointment.timeSlot.trim().isNotEmpty
        ? appointment.timeSlot.trim()
        : defaults.start;
    final start = _timeOnDate(startText);
    final end = _timeOnDate(defaults.end);
    if (start == null || end == null || !end.isAfter(start)) return startText;

    final shiftStart = _timeOnDate(defaults.start) ?? start;
    final queueNumber = appointment.queueNumber <= 0
        ? 1
        : appointment.queueNumber;
    final slotMinutes =
        end.difference(shiftStart).inMinutes / defaults.slotCount;
    final slotStart = shiftStart.add(
      Duration(minutes: ((queueNumber - 1) * slotMinutes).round()),
    );
    final slotEnd = shiftStart.add(
      Duration(minutes: (queueNumber * slotMinutes).round()),
    );
    return '${DateFormat('HH:mm').format(slotStart)} - ${DateFormat('HH:mm').format(slotEnd)}';
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

  Widget _buildPatientInfoCard(HospitalAppointmentModel appointment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÔNG TIN BỆNH NHÂN',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: Color(0xFF8A95AC),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.person_outline_rounded,
            'Bệnh nhân',
            appointment.patientName,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          _buildInfoRow(
            Icons.notes_rounded,
            'Triệu chứng',
            appointment.symptoms.isNotEmpty ? appointment.symptoms : 'Không có',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          _buildInfoRow(
            Icons.payments_outlined,
            'Chi phí',
            '${NumberFormat('#,###').format(appointment.consultationFee)} VNĐ',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6FC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF5A6680)),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5A6680),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF15233D),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
