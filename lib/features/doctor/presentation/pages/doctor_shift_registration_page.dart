import 'package:flutter/material.dart';

class DoctorShiftRegistrationPage extends StatefulWidget {
  const DoctorShiftRegistrationPage({super.key});

  @override
  State<DoctorShiftRegistrationPage> createState() => _DoctorShiftRegistrationPageState();
}

class _DoctorShiftRegistrationPageState extends State<DoctorShiftRegistrationPage> {
  DateTime _selectedDate = DateTime.now();
  final Map<int, String?> _registeredShifts = {}; // day -> shiftType

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('CHỌN NGÀY ĐĂNG KÝ'),
                  const SizedBox(height: 16),
                  _buildDateStrip(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('CA TRỰC TRONG NGÀY'),
                  const SizedBox(height: 16),
                  _buildShiftSlot('Sáng', '07:30 - 11:30', Icons.wb_sunny_rounded, const Color(0xFFD97706), '2/3'),
                  _buildShiftSlot('Chiều', '13:00 - 17:00', Icons.wb_twilight_rounded, const Color(0xFF0E47B5), '1/3'),
                  _buildShiftSlot('Tối', '18:00 - 22:00', Icons.nightlight_round_sharp, const Color(0xFF15233D), '0/3'),
                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 100,
      backgroundColor: const Color(0xFF0E47B5),
      title: const Text('Đăng ký ca trực', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0E47B5), Color(0xFF1654C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w900,
        color: Color(0xFF8A95AC),
      ),
    );
  }

  Widget _buildDateStrip() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // 2 weeks
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 65,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0E47B5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFF0E47B5).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekday(date.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : const Color(0xFF8A95AC),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : const Color(0xFF15233D),
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

  Widget _buildShiftSlot(String type, String time, IconData icon, Color color, String capacity) {
    final isRegistered = _registeredShifts[_selectedDate.day] == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isRegistered) {
            _registeredShifts.remove(_selectedDate.day);
          } else {
            _registeredShifts[_selectedDate.day] = type;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isRegistered ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRegistered ? color : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ca $type',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF15233D)),
                  ),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF5A6680)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isRegistered ? 'ĐÃ CHỌN' : 'CÒN TRỐNG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isRegistered ? color : const Color(0xFF0E9F6E),
                  ),
                ),
                Text(
                  'Số lượng: $capacity',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8A95AC)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E47B5).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký ca trực thành công!')),
          );
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E47B5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text(
          'XÁC NHẬN ĐĂNG KÝ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ),
    );
  }

  String _getWeekday(int day) {
    switch (day) {
      case 1: return 'T2';
      case 2: return 'T3';
      case 3: return 'T4';
      case 4: return 'T5';
      case 5: return 'T6';
      case 6: return 'T7';
      case 7: return 'CN';
      default: return '';
    }
  }
}
