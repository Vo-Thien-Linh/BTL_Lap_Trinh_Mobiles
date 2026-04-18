import 'package:flutter/material.dart';

class DoctorSchedulePage extends StatefulWidget {
  const DoctorSchedulePage({super.key});

  @override
  State<DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends State<DoctorSchedulePage> {
  DateTime _currentWeekStart = DateTime(2026, 2, 2); // Mock: Mon, Feb 2, 2026
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _currentWeekStart;
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
        title: const Text('Lịch làm việc', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
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
                  content: Text('Đang cập nhật lịch làm việc...'),
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
    final rangeText = "${_formatDateShort(_currentWeekStart)} - ${_formatDateShort(weekEnd)}";

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(Icons.chevron_left, () => _changeWeek(-1)),
          Column(
            children: [
              const Text('Tuần này', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0E47B5))),
              Text(rangeText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
            ],
          ),
          _navButton(Icons.chevron_right, () => _changeWeek(1)),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF3F6FC), borderRadius: BorderRadius.circular(12)),
      child: IconButton(onPressed: onTap, icon: Icon(icon, color: const Color(0xFF0E47B5))),
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
          final isSelected = dayDate.day == _selectedDay.day && dayDate.month == _selectedDay.month;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = dayDate),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0E47B5) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFF3F6FC)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(days[index], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white70 : const Color(0xFF8A95AC))),
                  const SizedBox(height: 4),
                  Text('${dayDate.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : const Color(0xFF15233D))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailySchedule() {
    final Map<int, List<Map<String, dynamic>>> mockSchedules = {
      1: [
        {
          'title': 'Ca sáng', 
          'time': '07:30 - 11:30', 
          'dept': 'Khoa Nội tổng quát', 
          'room': 'P.402 (Lầu 4)',
          'count': '15/30', 
          'color': const Color(0xFF0E47B5), 
          'status': 'Đang diễn ra',
          'patients': ['Nguyễn Văn A', 'Trần B', 'Lê C']
        },
      ],
      2: [
        {
          'title': 'Ca chiều', 
          'time': '13:30 - 17:30', 
          'dept': 'Khoa Nội tổng quát', 
          'room': 'P.101 (Trệt)',
          'count': '0/30', 
          'color': const Color(0xFF0E9F6E), 
          'status': 'Sắp tới',
          'patients': []
        },
      ],
      3: [
        {
          'title': 'Hội chẩn', 
          'time': '09:00 - 10:30', 
          'dept': 'Hội trường B', 
          'room': 'Khu A',
          'count': 'Chuyên khoa', 
          'color': const Color(0xFF7C3AED), 
          'status': 'Xác nhận',
          'patients': ['BS. Hưng', 'BS. Lan']
        },
        {
          'title': 'Ca chiều', 
          'time': '13:30 - 17:30', 
          'dept': 'Khoa Nội tổng quát', 
          'room': 'P.402 (Lầu 4)',
          'count': '5/10', 
          'color': const Color(0xFF0E9F6E), 
          'status': 'Sắp tới',
          'patients': ['Đỗ Thị P', 'Lý Hải']
        }
      ],
      5: [
        {
          'title': 'Ca sáng', 
          'time': '07:30 - 11:30', 
          'dept': 'Khoa Nội tổng quát', 
          'room': 'P.402 (Lầu 4)',
          'count': '10/30', 
          'color': const Color(0xFF0E47B5), 
          'status': 'Xác nhận',
          'patients': ['Phan Văn X']
        }
      ],
    };

    final dayIndex = _selectedDay.weekday;
    final dayShifts = mockSchedules[dayIndex] ?? [];

    // Helper to determine status dynamically
    Map<String, dynamic> _getDynamicStatus(String timeRange, DateTime day) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selected = DateTime(day.year, day.month, day.day);

      if (selected.isBefore(today)) {
        return {'label': 'Đã kết thúc', 'color': Colors.grey};
      } else if (selected.isAfter(today)) {
        return {'label': 'Sắp tới', 'color': const Color(0xFF0E9F6E)};
      } else {
        // Logics for TODAY
        try {
          final times = timeRange.split(' - ');
          final startParts = times[0].split(':');
          final endParts = times[1].split(':');
          
          final startTime = now.copyWith(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
          final endTime = now.copyWith(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));

          if (now.isBefore(startTime)) {
            return {'label': 'Sắp tới', 'color': const Color(0xFF0E9F6E)};
          } else if (now.isAfter(endTime)) {
            return {'label': 'Đã kết thúc', 'color': Colors.grey};
          } else {
            return {'label': 'Đang diễn ra', 'color': const Color(0xFFEB4D4B)}; // Red color for urgency
          }
        } catch (_) {
          return {'label': 'Xác nhận', 'color': const Color(0xFF0E47B5)};
        }
      }
    }

    if (dayShifts.isEmpty) {
      return _buildEmptyState('Hôm nay bạn không có lịch trực');
    }

    return Column(
      children: dayShifts.asMap().entries.map((entry) {
        final index = entry.key;
        final shift = entry.value;
        final statusInfo = _getDynamicStatus(shift['time'], _selectedDay);
        
        return _buildTimelineEntry(
          index: index,
          isLast: index == dayShifts.length - 1,
          shift: {...shift, 'status': statusInfo['label'], 'color': statusInfo['color']},
        );
      }).toList(),
    );
  }

  Widget _buildTimelineEntry({required int index, required bool isLast, required Map<String, dynamic> shift}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineIndicator(shift['color'], isLast),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _buildPremiumShiftCard(shift),
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
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
          ),
        ),
        if (!isLast)
          Expanded(
            child: Container(
              width: 2,
              color: color.withOpacity(0.2),
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumShiftCard(Map<String, dynamic> shift) {
    final Color color = shift['color'];

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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(shift['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                    ),
                    Text(shift['time'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF8A95AC))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(shift['title'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color.withOpacity(0.7))),
                Text(shift['dept'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(shift['room'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                    const Spacer(),
                    Icon(Icons.people_alt_rounded, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(shift['count'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5A6680))),
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
          Text(msg, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF8A95AC))),
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
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5A6680))),
      ],
    );
  }

  String _formatDateShort(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
