import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:baitaplon/features/appointment/domain/entities/appointment_entities.dart';
import '../../../../app/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';

class ExaminationResultDetailPage extends StatefulWidget {
  final HospitalAppointment appointment;

  const ExaminationResultDetailPage({
    super.key,
    required this.appointment,
  });

  @override
  State<ExaminationResultDetailPage> createState() => _ExaminationResultDetailPageState();
}

class _ExaminationResultDetailPageState extends State<ExaminationResultDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
            _buildHospitalBrandHeader(),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textHint,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                  tabs: const [
                    Tab(text: 'TỔNG QUAN'),
                    Tab(text: 'SINH TỒN'),
                    Tab(text: 'XÉT NGHIỆM'),
                    Tab(text: 'ĐƠN THUỐC'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildVitalsTab(),
            _buildLabResultsTab(),
            _buildPrescriptionTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      expandedHeight: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'PHIẾU KẾT QUẢ KHÁM BỆNH',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF3B82F6)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _handleShare(context),
          icon: const Icon(Icons.share_rounded, size: 20),
          tooltip: 'Chia sẻ kết quả khám',
        ),
      ],
    );
  }

  Widget _buildHospitalBrandHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF3B82F6)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HỆ THỐNG Y TẾ MEDCARE',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'International Standard Medical Services',
                          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBrandInfo('ID PHIẾU KHÁM', '#${widget.appointment.id.toUpperCase().substring(0, 8)}'),
                  _buildBrandInfo('NGÀY THỰC HIỆN', DateFormat('dd/MM/yyyy').format(widget.appointment.appointmentDate)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // --- TAB: OVERVIEW ---
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSummaryBanner(),
          const SizedBox(height: 20),
          _buildInfoSection(
            title: 'CHẨN ĐOÁN LÂM SÀNG',
            icon: Icons.assignment_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField('Tình trạng bệnh lý:', widget.appointment.diagnosis ?? 'Đang cập nhật...', isHighlight: true),
                const Divider(height: 32, color: AppColors.border),
                _buildField('Triệu chứng ghi nhận:', widget.appointment.symptoms),
                if (widget.appointment.physicalExam != null) ...[
                  const Divider(height: 32, color: AppColors.border),
                  _buildField('Kết quả khám thực thể:', widget.appointment.physicalExam!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildAdviceSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KẾT LUẬN CHUNG', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(
                  widget.appointment.diagnosis?.split('.').first ?? 'Tình trạng sức khỏe ổn định.',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB: VITALS ---
  Widget _buildVitalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoSection(
            title: 'CHỈ SỐ SINH TỒN',
            icon: Icons.monitor_heart_rounded,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildVitalCard('Huyết áp', '120/80', 'mmHg', AppColors.error, Icons.speed_rounded),
                _buildVitalCard('Nhịp tim', '75', 'bpm', const Color(0xFFF97316), Icons.favorite_rounded),
                _buildVitalCard('Nhiệt độ', '36.6', '°C', AppColors.primary, Icons.thermostat_rounded),
                _buildVitalCard('BMI', '22.5', 'Normal', AppColors.success, Icons.fitness_center_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoSection(
            title: 'BIỂU ĐỒ DIỄN BIẾN HUYẾT ÁP',
            icon: Icons.trending_up_rounded,
            child: Container(
              height: 220,
              padding: const EdgeInsets.only(top: 24, right: 16, bottom: 8),
              child: LineChart(
                LineChartData(
                    gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.border, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text('T${value.toInt() + 1}', style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [FlSpot(0, 110), FlSpot(1, 115), FlSpot(2, 120), FlSpot(3, 118), FlSpot(4, 122)],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB: LAB RESULTS ---
  Widget _buildLabResultsTab() {
    final labData = [
      {'name': 'Chỉ số Glucose', 'result': '5.2', 'unit': 'mmol/L', 'range': '3.9 - 6.4', 'status': 'Bình thường', 'trend': 'stable'},
      {'name': 'Cholesterol Tổng', 'result': '6.1', 'unit': 'mmol/L', 'range': '< 5.2', 'status': 'Vượt ngưỡng', 'trend': 'up'},
      {'name': 'Ure Máu', 'result': '4.5', 'unit': 'mmol/L', 'range': '2.5 - 7.5', 'status': 'Bình thường', 'trend': 'down'},
      {'name': 'Acid Uric', 'result': '320', 'unit': 'µmol/L', 'range': '200 - 420', 'status': 'Bình thường', 'trend': 'stable'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: labData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = labData[index];
        final bool isWarning = item['status'] != 'Bình thường';
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColors.textBody.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textBody)),
                  _buildStatusBadge(item['status']!, isWarning),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildLabInfoItem('KẾT QUẢ', '${item['result']} ${item['unit']}', isHighlight: true, trend: item['trend']),
                  Container(width: 1, height: 30, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 16)),
                  _buildLabInfoItem('NGƯỠNG AN TOÀN', item['range']!),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String text, bool isWarning) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.warning.withOpacity(0.12) : AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isWarning ? AppColors.warning : AppColors.success),
      ),
    );
  }

  Widget _buildLabInfoItem(String label, String value, {bool isHighlight = false, String? trend}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textHint, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
                  color: isHighlight ? AppColors.textBody : AppColors.textSecondary,
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: 4),
                _buildTrendIcon(trend),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIcon(String trend) {
    if (trend == 'up') return const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.warning);
    if (trend == 'down') return const Icon(Icons.trending_down_rounded, size: 14, color: AppColors.success);
    return const Icon(Icons.trending_flat_rounded, size: 14, color: AppColors.primary);
  }

  // --- TAB: PRESCRIPTION ---
  Widget _buildPrescriptionTab() {
    final prescriptions = widget.appointment.prescription ?? [];
    if (prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.not_interested_rounded, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            const Text('Không có đơn thuốc cho lần khám này.', style: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...prescriptions.map((item) => _buildPrescriptionTicket(item)).toList(),
        const SizedBox(height: 24),
        _buildPrescriptionFooter(),
      ],
    );
  }

  Widget _buildPrescriptionFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    const Text('BÁC SĨ CHẨN ĐOÁN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textBody, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(widget.appointment.doctorName.toUpperCase(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textBody)),
                const SizedBox(height: 4),
                const Text('Hệ Thống Y Tế Thông Minh v4.0', style: TextStyle(fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: AppColors.success, size: 14),
                      const SizedBox(width: 8),
                      Text('ĐÃ KÝ SỐ (VERIFIED)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: const Icon(Icons.qr_code_2_rounded, size: 64, color: AppColors.textBody),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionTicket(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.textBody.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.medication_rounded, size: 100, color: AppColors.primary.withOpacity(0.03)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'] ?? 'Tên thuốc', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textBody)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            item['dosage'] ?? 'Ngày 2 lần',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
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
      ),
    );
  }

  // --- COMPONENTS ---

  Widget _buildInfoSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.textBody.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildField(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textHint, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
            color: isHighlight ? AppColors.textBody : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVitalCard(String label, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withOpacity(0.8))),
              Icon(icon, color: color.withOpacity(0.6), size: 14),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textBody)),
                const WidgetSpan(child: SizedBox(width: 4)),
                TextSpan(text: unit, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryLight, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              const Text('HƯỚNG DẪN ĐIỀU TRỊ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: const Text('BÁC SĨ DẶN', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.appointment.treatment ?? 'Vui lòng tuân thủ liều lượng thuốc và nghỉ ngơi hợp lý.',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textBody, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: const Text('XUẤT BỆNH ÁN KỸ THUẬT SỐ', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _handleShare(BuildContext context) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('📋 PHIẾU KẾT QUẢ KHÁM BỆNH - MEDCARE');
      buffer.writeln('-----------------------------------');
      buffer.writeln('Mã phiếu: EXAM-${widget.appointment.id.substring(0, 8).toUpperCase()}');
      buffer.writeln('Bệnh nhân: ${widget.appointment.patientName}');
      buffer.writeln('Bác sĩ: ${widget.appointment.doctorName}');
      buffer.writeln('Khoa: ${widget.appointment.departmentName}');
      buffer.writeln('Ngày khám: ${DateFormat('dd/MM/yyyy').format(widget.appointment.appointmentDate)}');
      buffer.writeln('');
      buffer.writeln('CHẨN ĐOÁN:');
      buffer.writeln(widget.appointment.diagnosis ?? 'Đang cập nhật...');
      buffer.writeln('');
      buffer.writeln('KẾT LUẬN & LỜI DẶN:');
      buffer.writeln(widget.appointment.notes ?? 'Theo dõi thêm sức khỏe tại nhà.');
      buffer.writeln('-----------------------------------');
      buffer.writeln('Cài đặt MedCare để quản lý sức khỏe thông minh!');

      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        buffer.toString(),
        subject: 'Kết quả khám bệnh - ${widget.appointment.patientName}',
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chia sẻ kết quả: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabDelegate oldDelegate) => false;
}
