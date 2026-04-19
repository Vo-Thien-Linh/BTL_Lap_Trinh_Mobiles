import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/app_routes.dart';
import '../../data/models/appointment_models.dart';
import '../../../home/presentation/widgets/premium_login_required.dart';

class AppointmentManagementPage extends StatefulWidget {
  const AppointmentManagementPage({super.key});

  @override
  State<AppointmentManagementPage> createState() => _AppointmentManagementPageState();
}

class _AppointmentManagementPageState extends State<AppointmentManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isCalendarView = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                title: const Text(
                  'LỊCH HẸN CỦA TÔI',
                  style: TextStyle(
                    color: AppColors.textBody,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                background: _buildCountdownHeader(uid),
              ),
              actions: [
                _buildViewToggle(),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.booking),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'SẮP TỚI'),
                      Tab(text: 'LỊCH SỬ'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildUpcomingSection(uid),
            _buildHistoryList(uid),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownHeader(String? uid) {
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Appointments')
          .where('patientId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final appointments = snapshot.data!.docs
            .map((d) => HospitalAppointmentModel.fromFirestore(d))
            .where((a) => a.status != 'cancelled' && a.status != 'completed' && a.appointmentDate.isAfter(DateTime.now()))
            .toList();
        
        if (appointments.isEmpty) return const SizedBox.shrink();
        
        appointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
        final next = appointments.first;
        final difference = next.appointmentDate.difference(DateTime.now());
        final days = difference.inDays;
        final hours = difference.inHours % 24;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.05), AppColors.background],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 60),
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LỊCH HẸN TIẾP THEO CỦA BẠN',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.alarm_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    days > 0 ? 'Còn $days ngày $hours giờ' : 'Còn $hours giờ nữa',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textBody),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: () => setState(() => _isCalendarView = !_isCalendarView),
        icon: Icon(_isCalendarView ? Icons.list_alt_rounded : Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
        tooltip: _isCalendarView ? 'Xem danh sách' : 'Xem lịch tháng',
      ),
    );
  }

  Widget _buildUpcomingSection(String? uid) {
    if (_isCalendarView) {
      return _buildCalendarView(uid);
    }
    return _buildUpcomingList(uid);
  }

  Widget _buildCalendarView(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Appointments')
          .where('patientId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final appointments = snapshot.data?.docs.map((d) => HospitalAppointmentModel.fromFirestore(d)).toList() ?? [];

        return Column(
          children: [
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                return appointments.where((a) => isSameDay(a.appointmentDate, day)).toList();
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                markerDecoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _buildDayDetailList(appointments),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayDetailList(List<HospitalAppointmentModel> allAppointments) {
    if (_selectedDay == null) {
      return const Center(child: Text('Vui lòng chọn một ngày để xem chi tiết'));
    }

    final dayAppointments = allAppointments.where((a) => isSameDay(a.appointmentDate, _selectedDay)).toList();

    if (dayAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_rounded, size: 48, color: AppColors.textHint.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text('Không có lịch hẹn trong ngày này', style: TextStyle(color: AppColors.textHint)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: dayAppointments.length,
      itemBuilder: (context, index) => _MedicalTicketCard(appointment: dayAppointments[index]),
    );
  }

  Widget _buildUpcomingList(String? uid) {
    if (uid == null) {
      return const PremiumLoginRequired(
        title: 'LỊCH HẸN RIÊNG TƯ',
        description: 'Vui lòng đăng nhập để xem và quản lý các lịch hẹn sắp tới của bạn.',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Appointments')
          .where('patientId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs.map((d) => HospitalAppointmentModel.fromFirestore(d)).toList() ?? [];
        final upcoming = allDocs.where((a) {
          final isNotcancelled = a.status != 'cancelled';
          final isNotCompleted = a.status != 'completed';
          final isFuture = a.appointmentDate.isAfter(DateTime.now().subtract(const Duration(hours: 1)));
          return isNotcancelled && isNotCompleted && isFuture;
        }).toList();

        upcoming.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

        if (upcoming.isEmpty) {
          return _buildEmptyState('Bạn không có lịch hẹn sắp tới');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: upcoming.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, index) => _MedicalTicketCard(appointment: upcoming[index]),
        );
      },
    );
  }

  Widget _buildHistoryList(String? uid) {
    if (uid == null) {
      return const PremiumLoginRequired(
        title: 'LỊCH SỬ KHÁM BỆNH',
        description: 'Đăng nhập để xem lại toàn bộ lịch sử và kết quả các lần khám trước đây.',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Appointments')
          .where('patientId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs.map((d) => HospitalAppointmentModel.fromFirestore(d)).toList() ?? [];
        final history = allDocs.where((a) => a.status == 'completed' || a.status == 'cancelled' || a.appointmentDate.isBefore(DateTime.now())).toList();

        history.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

        if (history.isEmpty) {
          return _buildEmptyState('Chưa có lịch sử khám bệnh');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _CompactHistoryCard(appointment: history[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_busy_rounded, size: 64, color: AppColors.textHint.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.booking),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ĐẶT LỊCH NGAY'),
          ),
        ],
      ),
    );
  }
}

class _MedicalTicketCard extends StatelessWidget {
  final HospitalAppointmentModel appointment;
  const _MedicalTicketCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final bool isToday = isSameDay(appointment.appointmentDate, DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isToday ? AppColors.primary.withOpacity(0.12) : AppColors.textBody.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isToday)
            Positioned(
              top: 16,
              right: 16,
              child: _LiveBadge(),
            ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.doctorName.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textBody),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appointment.departmentName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: appointment.status),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoColumn(label: 'NGÀY KHÁM', value: DateFormat('dd/MM/yyyy').format(appointment.appointmentDate)),
                        _InfoColumn(label: 'GIỜ KHÁM', value: appointment.timeSlot),
                        _InfoColumn(label: 'SỐ THỨ TỰ', value: '#${appointment.queueNumber}', isHighlight: true),
                      ],
                    ),
                  ],
                ),
              ),
              _buildDottedDivider(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'PHÒNG: ${appointment.roomNumber}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textBody),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _ActionIcon(icon: Icons.map_outlined, onTap: () {}),
                              const SizedBox(width: 12),
                              _ActionIcon(icon: Icons.info_outline_rounded, color: AppColors.success, onTap: () => _showPrepGuide(context)),
                              const SizedBox(width: 12),
                              _ActionIcon(icon: Icons.cancel_outlined, color: AppColors.error, onTap: () {}),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showQRModal(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.qr_code_2_rounded, size: 34, color: AppColors.textBody),
                            const SizedBox(height: 4),
                            const Text(
                              'CHECK-IN',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPrepGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HƯỚNG DẪN CHUẨN BỊ',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.0),
            ),
            const SizedBox(height: 24),
            _buildGuideItem(Icons.fastfood_rounded, 'Nhịn ăn ít nhất 8 tiếng nếu có xét nghiệm máu.'),
            _buildGuideItem(Icons.description_rounded, 'Mang theo sổ khám bệnh và các đơn thuốc đang sử dụng.'),
            _buildGuideItem(Icons.timer_rounded, 'Vui lòng đến trước 15 phút để làm thủ tục check-in.'),
            _buildGuideItem(Icons.attribution_rounded, 'Mặc trang phục thoải mái để dễ dàng thăm khám.'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('TÔI ĐÃ HIỂU', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildDottedDivider() {
    return Row(
      children: List.generate(40, (index) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          height: 1.5,
          color: index % 2 == 0 ? Colors.transparent : AppColors.border,
        ),
      )),
    );
  }

  void _showQRModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'XÁC NHẬN ĐIỂM DANH',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vui lòng đưa mã này vào máy quét tại sảnh chờ',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 40)],
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: QrImageView(
                data: appointment.id,
                version: QrVersions.auto,
                size: 220.0,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: AppColors.primary),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'STT: #${appointment.queueNumber}',
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 18, letterSpacing: 2),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(CurveTween(curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(8)),
        child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }
}

class _CompactHistoryCard extends StatelessWidget {
  final HospitalAppointmentModel appointment;
  const _CompactHistoryCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = appointment.status == 'cancelled';
    return InkWell(
      onTap: () {
        if (appointment.status == 'completed') {
           Navigator.pushNamed(context, AppRoutes.examinationDetail, arguments: appointment);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCancelled ? AppColors.error.withOpacity(0.1) : AppColors.primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isCancelled ? Icons.cancel_rounded : Icons.history_edu_rounded,
                color: isCancelled ? AppColors.error : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.doctorName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textBody),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy • HH:mm').format(appointment.appointmentDate),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.border, size: 14),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'confirmed':
        color = AppColors.success;
        label = 'ĐÃ XÁC NHẬN';
        break;
      case 'pending':
        color = AppColors.warning;
        label = 'CHỜ XỬ LÝ';
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'ĐÃ HỦY';
        break;
      default:
        color = AppColors.textSecondary;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  const _InfoColumn({required this.label, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textHint, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: isHighlight ? AppColors.primary : AppColors.textBody,
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _ActionIcon({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
    );
  }
}
