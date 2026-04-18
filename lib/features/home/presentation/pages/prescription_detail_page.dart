import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:baitaplon/features/appointment/domain/entities/appointment_entities.dart';
import '../../../../app/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';

class PrescriptionDetailPage extends StatelessWidget {
  final HospitalAppointment appointment;
  const PrescriptionDetailPage({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final prescriptions = appointment.prescription ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildMainHeaderCard(),
                   const SizedBox(height: 32),
                   Row(
                     children: [
                       Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                       const SizedBox(width: 8),
                       const Text(
                        'DANH SÁCH THUỐC KÊ ĐƠN',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.0),
                       ),
                     ],
                   ),
                   const SizedBox(height: 16),
                   ...prescriptions.map((med) => _buildMedicationCard(med)).toList(),
                   const SizedBox(height: 24),
                   _buildDoctorAdviceSection(),
                    const SizedBox(height: 120), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildSmartReminderButton(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      expandedHeight: 140,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('CHI TIẾT ĐƠN THUỐC', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF3B82F6)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
            ),
            Opacity(
              opacity: 0.1,
              child: Container(
                 decoration: const BoxDecoration(
                   image: DecorationImage(
                     image: NetworkImage('https://www.transparenttextures.com/patterns/white-diamond.png'),
                     repeat: ImageRepeat.repeat,
                   ),
                 ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _handleShare(context),
          icon: const Icon(Icons.share_rounded, size: 20),
          tooltip: 'Chia sẻ đơn thuốc',
        ),
      ],
    );
  }

  Widget _buildMainHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MÃ SỐ ĐƠN THUỐC', style: TextStyle(color: AppColors.textHint, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text('PRES-${appointment.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textBody)),
                  ],
                ),
              ),
              Column(
                children: [
                   const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
                   const SizedBox(height: 4),
                   const Text('VERIFIED', style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              _buildHeaderInfoItem('Bác sĩ kê đơn', appointment.doctorName, Icons.person_rounded),
              const Spacer(),
              _buildHeaderInfoItem('Ngày kê', DateFormat('dd MMM, yyyy').format(appointment.appointmentDate), Icons.today_rounded),
            ],
          ),
          const SizedBox(height: 20),
          _buildHeaderInfoItem('Chuyên khoa', appointment.departmentName, Icons.account_balance_rounded),
        ],
      ),
    );
  }

  Widget _buildHeaderInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: AppColors.textHint, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textBody)),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.textBody.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMedicationIcon(med['name'] ?? ''),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med['name'] ?? 'Tên thuốc', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textBody)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                            child: Text('SL: ${med['quantity'] ?? "01"}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 10)),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time_filled_rounded, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(med['usage'] ?? 'Sau ăn', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                _buildScheduleBadge(Icons.wb_sunny_rounded, 'SÁNG', true),
                const SizedBox(width: 8),
                _buildScheduleBadge(Icons.wb_twilight_rounded, 'TRƯA', false),
                const SizedBox(width: 8),
                _buildScheduleBadge(Icons.nightlight_round, 'TỐI', true),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('LIỀU DÙNG', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textHint, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(med['dosage'] ?? '1 viên/lần', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textBody)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationIcon(String name) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Icon(
          name.toLowerCase().contains('siro') ? Icons.liquor_rounded : Icons.medication_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildScheduleBadge(IconData icon, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.orange : AppColors.textHint, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isActive ? AppColors.textBody : AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _buildDoctorAdviceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('HƯỚNG DẪN ĐIỀU TRỊ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            appointment.notes ?? 'Uống thuốc đúng giờ, tái khám sau 7 ngày hoặc khi có triệu chứng bất thường. Hạn chế thức ăn cay nóng và vận động mạnh.',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.6, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TÁC DỤNG PHỤ CẦN LƯU Ý', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                      Text('Có thể gây buồn ngủ nhẹ, tránh lái xe sau khi dùng thuốc.', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSmartReminderButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _showReminderSetup(context),
          icon: const Icon(Icons.notifications_active_rounded, size: 22),
          label: const Text('NHẮC LỊCH UỐNG THUỐC', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
  void _showReminderSetup(BuildContext context) {
    final prescriptions = appointment.prescription ?? [];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.alarm_add_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THIẾT LẬP NHẮC LỊCH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textBody)),
                      Text('Kiểm tra lịch trình uống thuốc của bạn', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: prescriptions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final med = prescriptions[index];
                  final dosage = med['dosage'] ?? '';
                  final isMorning = dosage.contains('Sáng');
                  final isNoon = dosage.contains('Trưa');
                  final isEvening = dosage.contains('Tối');
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(med['name'] ?? 'Tên thuốc', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textBody)),
                              const SizedBox(height: 4),
                              Text(med['dosage'] ?? '1 viên/lần', style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (isMorning) _buildSimpleSessionIcon(Icons.wb_sunny_rounded, Colors.orange),
                            if (isNoon) _buildSimpleSessionIcon(Icons.wb_twilight_rounded, Colors.orange),
                            if (isEvening) _buildSimpleSessionIcon(Icons.nightlight_round, Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã kích hoạt lịch nhắc nhở uống thuốc!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('XÁC NHẬN THIẾT LẬP', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleSessionIcon(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('💊 ĐƠN THUỐC MEDCARE');
      buffer.writeln('----------------------------');
      buffer.writeln('Mã đơn: PRES-${appointment.id.substring(0, 8).toUpperCase()}');
      buffer.writeln('Bác sĩ: ${appointment.doctorName}');
      buffer.writeln('Chuyên khoa: ${appointment.departmentName}');
      buffer.writeln('Ngày kê: ${DateFormat('dd/MM/yyyy').format(appointment.appointmentDate)}');
      buffer.writeln('');
      buffer.writeln('DANH SÁCH THUỐC:');
      
      final prescriptions = appointment.prescription ?? [];
      if (prescriptions.isEmpty) {
        buffer.writeln('(Chưa có danh sách thuốc)');
      } else {
        for (var med in prescriptions) {
          buffer.writeln('- ${med['name'] ?? 'Thuốc'}: ${med['quantity'] ?? "01"} (${med['dosage'] ?? "Theo chỉ dẫn"})');
          buffer.writeln('  Cách dùng: ${med['usage'] ?? "Uống sau ăn"}');
        }
      }
      
      buffer.writeln('');
      buffer.writeln('LỜI DẶN BÁC SĨ:');
      buffer.writeln(appointment.notes ?? 'Uống thuốc đúng giờ, tái khám đúng hẹn.');
      buffer.writeln('----------------------------');
      buffer.writeln('Ứng dụng MedCare - Đồng hành cùng sức khỏe của bạn');

      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        buffer.toString(),
        subject: 'Đơn thuốc MedCare - ${appointment.doctorName}',
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chia sẻ: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
