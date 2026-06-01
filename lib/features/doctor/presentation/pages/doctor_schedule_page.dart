import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorSchedulePage extends StatefulWidget {
  const DoctorSchedulePage({super.key});

  @override
  State<DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends State<DoctorSchedulePage> {
  late DateTime _currentWeekStart;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    // Find Monday of the current week
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    _currentWeekStart = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
  }

  void _changeWeek(int delta) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: delta * 7));
      _selectedDay = _currentWeekStart;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        title: const Text(
          'Lịch hẹn',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0E47B5),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang cập nhật lịch hẹn...'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Color(0xFF0E47B5),
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekNavigator(),
          _buildDaySelector(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: _buildDailySchedule(),
            ),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final rangeText =
        "${_formatDateShort(_currentWeekStart)} - ${_formatDateShort(weekEnd)}";

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(Icons.chevron_left, () => _changeWeek(-1)),
          Column(
            children: [
              const Text(
                'Tuần này',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0E47B5),
                ),
              ),
              Text(
                rangeText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15233D),
                ),
              ),
            ],
          ),
          _navButton(Icons.chevron_right, () => _changeWeek(1)),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFF0E47B5)),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      height: 90,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final dayDate = _currentWeekStart.add(Duration(days: index));
          final isSelected =
              dayDate.day == _selectedDay.day &&
              dayDate.month == _selectedDay.month;

          return GestureDetector(
            onTap: () => setState(() => _selectedDay = dayDate),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0E47B5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : const Color(0xFFF3F6FC),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white70
                          : const Color(0xFF8A95AC),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dayDate.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF15233D),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailySchedule() {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null)
      return const Center(child: Text('Vui lòng đăng nhập'));

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('Doctors')
          .where('userId', isEqualTo: currentUid)
          .limit(1)
          .get(),
      builder: (context, doctorSnap) {
        if (doctorSnap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        String actualDoctorId = currentUid;
        if (doctorSnap.hasData && doctorSnap.data!.docs.isNotEmpty) {
          actualDoctorId = doctorSnap.data!.docs.first.id;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Appointments')
              .where('doctorId', isEqualTo: actualDoctorId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final allDocs = snapshot.data?.docs ?? [];

            // Lọc các appointment vào đúng ngày được chọn
            final selectedDateStr =
                '${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}';

            final todayAppointments = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              String apptDateStr = '';
              if (data['appointmentDate'] is Timestamp) {
                final date = (data['appointmentDate'] as Timestamp).toDate();
                apptDateStr =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              } else if (data['appointmentDate'] != null) {
                apptDateStr = data['appointmentDate'].toString();
              }
              return apptDateStr.startsWith(selectedDateStr) ||
                  apptDateStr == selectedDateStr;
            }).toList();

            if (todayAppointments.isEmpty) {
              return _buildEmptyState('Bạn không có lịch hẹn nào vào ngày này');
            }

            // Sort by time
            todayAppointments.sort((a, b) {
              final tA =
                  (a.data() as Map<String, dynamic>)['appointmentTime'] ??
                  '00:00';
              final tB =
                  (b.data() as Map<String, dynamic>)['appointmentTime'] ??
                  '00:00';
              return tA.compareTo(tB);
            });

            return Column(
              children: todayAppointments.asMap().entries.map((entry) {
                final index = entry.key;
                final doc = entry.value;
                final data = doc.data() as Map<String, dynamic>;

                return _buildTimelineEntry(
                  index: index,
                  isLast: index == todayAppointments.length - 1,
                  data: data,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineEntry({
    required int index,
    required bool isLast,
    required Map<String, dynamic> data,
  }) {
    final status = data['status']?.toString() ?? 'pending';
    Color color = const Color(0xFF0E47B5);
    String displayStatus = 'Sắp tới';

    if (status == 'completed') {
      color = Colors.grey;
      displayStatus = 'Đã khám';
    } else if (status == 'ongoing' || status == 'calling') {
      color = const Color(0xFFEB4D4B);
      displayStatus = 'Đang khám';
    } else if (status == 'cancelled') {
      color = Colors.red;
      displayStatus = 'Đã hủy';
    } else if (status == 'cancel_requested') {
      color = Colors.orange;
      displayStatus = 'Chờ duyệt hủy';
    } else if (status == 'no_show' || status == 'absent') {
      color = Colors.orange;
      displayStatus = 'Vắng mặt';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineIndicator(color, isLast),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _buildAppointmentCard(data, color, displayStatus),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator(Color color, bool isLast) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 4),
            ],
          ),
        ),
        if (!isLast)
          Expanded(child: Container(width: 2, color: color.withOpacity(0.2))),
      ],
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> data,
    Color color,
    String displayStatus,
  ) {
    final patientName = data['patientName'] ?? 'Bệnh nhân';
    final time = data['appointmentTime'] ?? '00:00';
    final reason = data['reason'] ?? 'Khám bệnh';
    final age = data['patientAge']?.toString() ?? '??';
    final gender = data['patientGender']?.toString() ?? 'Chưa rõ';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        displayStatus,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF15233D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  patientName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF15233D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$age tuổi • $gender',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A95AC),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.notes_rounded, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            msg,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8A95AC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F4FA))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem('Ca sáng', const Color(0xFF0E47B5)),
          _legendItem('Ca chiều', const Color(0xFF0E9F6E)),
          _legendItem('Nghỉ', Colors.grey),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A6680),
          ),
        ),
      ],
    );
  }

  String _formatDateShort(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
