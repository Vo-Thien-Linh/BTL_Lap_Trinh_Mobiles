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
        title: const Text('Chi tiết lịch hẹn', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF15233D),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Appointments').doc(appointmentId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Không tìm thấy thông tin lịch hẹn', style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          final appointment = HospitalAppointmentModel.fromFirestore(snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusBanner(appointment.status),
                const SizedBox(height: 16),
                _buildDoctorInfo(appointment),
                const SizedBox(height: 16),
                _buildTimeLocationCard(appointment),
                const SizedBox(height: 16),
                _buildPatientInfoCard(appointment),
                const SizedBox(height: 24),
                if (appointment.status == 'scheduled' || appointment.status == 'pending')
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('QUẢN LÝ LỊCH HẸN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                if (appointment.status == 'completed')
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.examinationDetail, arguments: appointment);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('XEM KẾT QUẢ KHÁM', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
      case 'in_progress':
      case 'arrived':
        bgColor = const Color(0xFFE1EFFE);
        textColor = const Color(0xFF1A56DB);
        text = 'Đang khám';
        icon = Icons.sync_rounded;
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
          Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDoctorInfo(HospitalAppointmentModel appointment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF15233D)),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.departmentName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primary),
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_month_rounded, 'Ngày khám', DateFormat('dd/MM/yyyy').format(appointment.appointmentDate)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          _buildInfoRow(Icons.access_time_rounded, 'Giờ khám', appointment.timeSlot.isNotEmpty ? appointment.timeSlot : 'Chưa cập nhật'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          _buildInfoRow(Icons.pin_drop_rounded, 'Phòng khám', appointment.roomNumber.isNotEmpty ? appointment.roomNumber : 'Chờ phân phòng'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          _buildInfoRow(Icons.format_list_numbered_rounded, 'Số thứ tự', appointment.queueNumber > 0 ? appointment.queueNumber.toString() : '---'),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard(HospitalAppointmentModel appointment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('THÔNG TIN BỆNH NHÂN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF8A95AC), letterSpacing: 0.5)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person_outline_rounded, 'Bệnh nhân', appointment.patientName),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          _buildInfoRow(Icons.notes_rounded, 'Triệu chứng', appointment.symptoms.isNotEmpty ? appointment.symptoms : 'Không có'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          _buildInfoRow(Icons.payments_outlined, 'Chi phí', '${NumberFormat('#,###').format(appointment.consultationFee)} VNĐ'),
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
        Text(label, style: const TextStyle(color: Color(0xFF5A6680), fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xFF15233D), fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
