import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../features/appointment/data/models/appointment_models.dart';
import '../../../../features/appointment/domain/entities/appointment_entities.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../widgets/premium_login_required.dart';

class ExaminationHistoryPage extends StatefulWidget {
  final bool isSubPage;
  final String? defaultFilter;
  const ExaminationHistoryPage({super.key, this.isSubPage = false, this.defaultFilter});

  @override
  State<ExaminationHistoryPage> createState() => _ExaminationHistoryPageState();
}

class _ExaminationHistoryPageState extends State<ExaminationHistoryPage> {
  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Chờ xử lý', 'Đã xác nhận', 'Hoàn thành', 'Đã hủy'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.defaultFilter != null) {
      final mapping = {
        'pending': 'Chờ xử lý',
        'confirmed': 'Đã xác nhận',
        'completed': 'Hoàn thành',
        'cancelled': 'Đã hủy'
      };
      _selectedFilter = mapping[widget.defaultFilter] ?? 'Tất cả';
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    // Simulating fetching fresh data from Firestore
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedFilter = 'Tất cả';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật dòng thời gian y tế mới nhất'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'DÒNG THỜI GIAN Y TẾ',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textBody),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isSubPage 
            ? null 
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textBody),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))))
            : IconButton(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textBody),
              ),
        ],
      ),
      body: Column(
        children: [
          _buildTopSummary(uid),
          _buildFilterBar(),
          Expanded(
            child: uid == null 
                ? const PremiumLoginRequired(
                    title: 'LỊCH SỬ KHÁM RIÊNG TƯ',
                    description: 'Vui lòng đăng nhập để truy cập dòng thời gian lịch sử các lần khám bệnh của bạn.',
                  )
                : _buildTimelineStream(uid),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSummary(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: uid == null ? null : FirebaseFirestore.instance.collection('Appointments').where('patientId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        int totalVisits = snapshot.hasData ? snapshot.data!.docs.length : 0;
        int completed = snapshot.hasData ? snapshot.data!.docs.where((d) => d.get('status') == 'completed').length : 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Tổng lượt khám', totalVisits.toString(), Icons.analytics_rounded),
              Container(width: 1, height: 40, color: AppColors.border),
              _buildStatItem('Đã hoàn thành', completed.toString(), Icons.verified_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: AppColors.textBody, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = _filters[index];
          final isSelected = _selectedFilter == f;
          return InkWell(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Text(f, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 11)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineStream(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Appointments').where('patientId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        var list = snapshot.data?.docs.map((d) => HospitalAppointmentModel.fromFirestore(d)).toList() ?? [];
        if (list.isEmpty) list = _getMockHistory();

        // Filtering
        if (_selectedFilter != 'Tất cả') {
          final mapping = {'Chờ xử lý': 'pending', 'Đã xác nhận': 'confirmed', 'Hoàn thành': 'completed', 'Đã hủy': 'cancelled'};
          list = list.where((a) => a.status == mapping[_selectedFilter]).toList();
        }
        list.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

        if (list.isEmpty) return const Center(child: Text('Không có dữ liệu', style: TextStyle(color: AppColors.textHint)));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                // Timeline Connector
                if (index != list.length - 1)
                  Positioned(
                    left: 27,
                    top: 40,
                    bottom: 0,
                    child: Container(width: 2, color: AppColors.border),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline Indicator
                      _buildTimelineIndicator(list[index].status),
                      const SizedBox(width: 16),
                      Expanded(child: _PremiumTimelineCard(appointment: list[index])),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineIndicator(String status) {
    Color color;
    IconData icon;
    switch(status) {
      case 'completed': color = AppColors.success; icon = Icons.check_circle_rounded; break;
      case 'confirmed': color = AppColors.primary; icon = Icons.event_available_rounded; break;
      case 'pending': color = AppColors.warning; icon = Icons.pending_rounded; break;
      case 'cancelled': color = AppColors.error; icon = Icons.cancel_rounded; break;
      default: color = Colors.grey; icon = Icons.circle;
    }

    return Container(
      width: 56,
      child: Column(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, spreadRadius: 2)],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }

  List<HospitalAppointmentModel> _getMockHistory() {
    return [
      HospitalAppointmentModel(
        id: 'M-1', patientId: 'uid', patientName: 'User', doctorId: 'd1', doctorName: 'ThS.BS Nguyễn Văn An',
        departmentId: 'dep1', departmentName: 'Khoa Nội Tổng Quát',
        appointmentDate: DateTime.now().subtract(const Duration(days: 2)),
        shiftId: 's1', timeSlot: '08:00 - 08:30', queueNumber: 15, roomNumber: 'A102',
        consultationFee: 150000, symptoms: 'Đau đầu, mệt mỏi', diagnosis: 'Suy nhược cơ thể nhẹ', status: 'completed',
        paymentMethod: 'CASH', createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      HospitalAppointmentModel(
        id: 'M-2', patientId: 'uid', patientName: 'User', doctorId: 'd2', doctorName: 'BSCKII. Lê Thị Minh',
        departmentId: 'dep2', departmentName: 'Khoa Tai Mũi Họng',
        appointmentDate: DateTime.now().add(const Duration(days: 1)),
        shiftId: 's2', timeSlot: '14:30 - 15:00', queueNumber: 5, roomNumber: 'B205',
        consultationFee: 200000, symptoms: 'Viêm họng', status: 'confirmed',
        paymentMethod: 'BANK', createdAt: DateTime.now(),
      ),
    ];
  }
}

class _PremiumTimelineCard extends StatelessWidget {
  final HospitalAppointmentModel appointment;
  const _PremiumTimelineCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    bool isCompleted = appointment.status == 'completed';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: AppColors.textBody.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('dd MMM, yyyy').format(appointment.appointmentDate).toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
              _buildPaymentBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Text(appointment.doctorName, style: const TextStyle(color: AppColors.textBody, fontSize: 16, fontWeight: FontWeight.w900)),
          Text(appointment.departmentName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (isCompleted) ...[
             _buildDiagnosisSnippet(),
             const SizedBox(height: 16),
          ],
          _buildCardActions(context),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          const Icon(Icons.payments_rounded, color: AppColors.success, size: 10),
          const SizedBox(width: 4),
          Text('${NumberFormat.currency(locale: "vi_VN", symbol: "đ").format(appointment.consultationFee)}', style: const TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildDiagnosisSnippet() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CHẨN ĐOÁN', style: TextStyle(color: AppColors.textHint, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(appointment.diagnosis ?? "Đã có bệnh án chi tiết", style: const TextStyle(color: AppColors.textBody, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildCardActions(BuildContext context) {
    if (appointment.status != 'completed') return const SizedBox.shrink();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionChip(context, 'KẾT QUẢ', Icons.description_rounded, () {
             Navigator.pushNamed(context, AppRoutes.examinationDetail, arguments: appointment);
          }),
          const SizedBox(width: 8),
          _buildActionChip(context, 'TOA THUỐC', Icons.medication_rounded, () {
             Navigator.pushNamed(context, AppRoutes.prescriptionDetail, arguments: appointment);
          }),
          const SizedBox(width: 8),
          _buildActionChip(context, 'BIÊN LAI', Icons.receipt_rounded, () {
             _showInvoiceDialog(context, appointment);
          }),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  void _showInvoiceDialog(BuildContext context, HospitalAppointment appointment) {
    // Giả lập một số chi phí dựa trên dữ liệu thực tế
    final consultationFee = appointment.consultationFee;
    final labFee = (appointment.labResults?.isNotEmpty ?? false) ? 150000.0 : 0.0;
    final medicineFee = (appointment.prescription?.isNotEmpty ?? false) ? 245000.0 : 0.0;
    final totalFee = consultationFee + labFee + medicineFee;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Biên lai
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 40),
                    const SizedBox(height: 12),
                    const Text('BIÊN LAI THANH TOÁN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    Text('Mã HD: INV-${appointment.id.substring(0, 8).toUpperCase()}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin chung
                    _buildInvoiceRow('Bệnh nhân', appointment.patientName, isBold: true),
                    _buildInvoiceRow('Bác sĩ', appointment.doctorName),
                    _buildInvoiceRow('Ngày khám', DateFormat('dd/MM/yyyy').format(appointment.appointmentDate)),
                    _buildInvoiceRow('Khoa', appointment.departmentName),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),

                    // Chi tiết phí
                    const Text('CHI TIẾT DỊCH VỤ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textHint, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    _buildFeeItem('Phí khám chuyên khoa', consultationFee),
                    if (labFee > 0) _buildFeeItem('Phí dịch vụ xét nghiệm', labFee),
                    if (medicineFee > 0) _buildFeeItem('Phí thuốc kê đơn', medicineFee),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: DashedDivider(),
                    ),

                    // Tổng tiền
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TỔNG THANH TOÁN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textBody)),
                        Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(totalFee),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Status Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.success, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('ĐÃ THANH TOÁN', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.background,
                          foregroundColor: AppColors.textBody,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('ĐÓNG', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: AppColors.textBody, fontSize: 12, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFeeItem(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textBody, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount), style: const TextStyle(color: AppColors.textBody, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: AppColors.border)),
            );
          }),
        );
      },
    );
  }
}
