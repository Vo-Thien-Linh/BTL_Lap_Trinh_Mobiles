import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:baitaplon/features/appointment/domain/entities/appointment_entities.dart';
import '../../../../app/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';

class PrescriptionDetailPage extends StatelessWidget {
  final HospitalAppointment appointment;
  PrescriptionDetailPage({super.key, required this.appointment});

  static String _medText(
    Map<String, dynamic> med,
    String key, {
    String fallback = '',
  }) {
    final value = med[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

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
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainHeaderCard(),
                  SizedBox(height: 32),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'DANH SÁCH THUỐC KÊ ĐƠN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...prescriptions
                      .map((med) => _buildMedicationCard(med))
                      .toList(),
                  SizedBox(height: 24),
                  _buildDoctorAdviceSection(),
                  SizedBox(height: 120), // Space for FAB
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
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'CHI TIẾT ĐƠN THUỐC',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Opacity(
              opacity: 0.1,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://www.transparenttextures.com/patterns/white-diamond.png',
                    ),
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
          icon: Icon(Icons.share_rounded, size: 20),
          tooltip: 'Chia sẻ đơn thuốc',
        ),
      ],
    );
  }

  Widget _buildMainHeaderCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MÃ SỐ ĐƠN THUỐC',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'PRES-${appointment.id.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'VERIFIED',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              _buildHeaderInfoItem(
                'Bác sĩ kê đơn',
                appointment.doctorName,
                Icons.person_rounded,
              ),
              const Spacer(),
              _buildHeaderInfoItem(
                'Ngày kê',
                DateFormat('dd MMM, yyyy').format(appointment.appointmentDate),
                Icons.today_rounded,
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildHeaderInfoItem(
            'Chuyên khoa',
            appointment.departmentName,
            Icons.account_balance_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                color: AppColors.textHint,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textBody,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> med) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBody.withOpacity(0.02),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMedicationIcon(_medText(med, 'name')),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _medText(med, 'name', fallback: 'Tên thuốc'),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.textBody,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SL: ${_medText(med, 'quantity', fallback: '01')}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.access_time_filled_rounded,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _medText(med, 'usage', fallback: 'Sau ăn'),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                _buildScheduleBadge(Icons.wb_sunny_rounded, 'SÁNG', true),
                SizedBox(width: 8),
                _buildScheduleBadge(Icons.wb_twilight_rounded, 'TRƯA', false),
                SizedBox(width: 8),
                _buildScheduleBadge(Icons.nightlight_round, 'TỐI', true),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LIỀU DÙNG',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textHint,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _medText(med, 'dosage', fallback: '1 viên/lần'),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.textBody,
                      ),
                    ),
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
          name.toLowerCase().contains('siro')
              ? Icons.liquor_rounded
              : Icons.medication_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildScheduleBadge(IconData icon, String label, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.orange : AppColors.textHint,
            size: 14,
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isActive ? AppColors.textBody : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorAdviceSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'HƯỚNG DẪN ĐIỀU TRỊ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            appointment.notes ??
                'Uống thuốc đúng giờ, tái khám sau 7 ngày hoặc khi có triệu chứng bất thường. Hạn chế thức ăn cay nóng và vận động mạnh.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TÁC DỤNG PHỤ CẦN LƯU Ý',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Có thể gây buồn ngủ nhẹ, tránh lái xe sau khi dùng thuốc.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
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
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _showReminderSetup(context),
          icon: Icon(Icons.notifications_active_rounded, size: 22),
          label: Text(
            'NHẮC LỊCH UỐNG THUỐC',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.alarm_add_rounded,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THIẾT LẬP NHẮC LỊCH',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textBody,
                        ),
                      ),
                      Text(
                        'Kiểm tra lịch trình uống thuốc của bạn',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: prescriptions.length,
                separatorBuilder: (_, __) => SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final med = prescriptions[index];
                  final dosage = _medText(med, 'dosage');
                  final isMorning = dosage.contains('Sáng');
                  final isNoon = dosage.contains('Trưa');
                  final isEvening = dosage.contains('Tối');

                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _medText(med, 'name', fallback: 'Tên thuốc'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.textBody,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _medText(med, 'dosage', fallback: '1 viên/lần'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (isMorning)
                              _buildSimpleSessionIcon(
                                Icons.wb_sunny_rounded,
                                Colors.orange,
                              ),
                            if (isNoon)
                              _buildSimpleSessionIcon(
                                Icons.wb_twilight_rounded,
                                Colors.orange,
                              ),
                            if (isEvening)
                              _buildSimpleSessionIcon(
                                Icons.nightlight_round,
                                Colors.orange,
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'XÁC NHẬN THIẾT LẬP',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
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
      buffer.writeln(
        'Mã đơn: PRES-${appointment.id.substring(0, 8).toUpperCase()}',
      );
      buffer.writeln('Bác sĩ: ${appointment.doctorName}');
      buffer.writeln('Chuyên khoa: ${appointment.departmentName}');
      buffer.writeln(
        'Ngày kê: ${DateFormat('dd/MM/yyyy').format(appointment.appointmentDate)}',
      );
      buffer.writeln('');
      buffer.writeln('DANH SÁCH THUỐC:');

      final prescriptions = appointment.prescription ?? [];
      if (prescriptions.isEmpty) {
        buffer.writeln('(Chưa có danh sách thuốc)');
      } else {
        for (var med in prescriptions) {
          buffer.writeln(
            '- ${_medText(med, 'name', fallback: 'Thuốc')}: ${_medText(med, 'quantity', fallback: "01")} (${_medText(med, 'dosage', fallback: "Theo chỉ dẫn")})',
          );
          buffer.writeln(
            '  Cách dùng: ${_medText(med, 'usage', fallback: "Uống sau ăn")}',
          );
        }
      }

      buffer.writeln('');
      buffer.writeln('LỜI DẶN BÁC SĨ:');
      buffer.writeln(
        appointment.notes ?? 'Uống thuốc đúng giờ, tái khám đúng hẹn.',
      );
      buffer.writeln('----------------------------');
      buffer.writeln(
        'Ứng dụng Bệnh viện LPHV - Đồng hành cùng sức khỏe của bạn',
      );

      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        buffer.toString(),
        subject: 'Đơn thuốc Bệnh viện LPHV - ${appointment.doctorName}',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
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
