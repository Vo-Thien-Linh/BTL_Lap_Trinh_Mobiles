import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorShiftRegistrationPage extends StatefulWidget {
  const DoctorShiftRegistrationPage({super.key});

  @override
  State<DoctorShiftRegistrationPage> createState() =>
      _DoctorShiftRegistrationPageState();
}

class _DoctorShiftRegistrationPageState
    extends State<DoctorShiftRegistrationPage> {
  DateTime _selectedDate = DateTime.now();
  final Map<int, String?> _registeredShifts = {}; // day -> shiftType
  final TextEditingController _doctorIdController = TextEditingController();
  String? _selectedDoctorId;
  late Future<_DoctorShiftInfo?> _doctorInfoFuture;

  @override
  void initState() {
    super.initState();
    _doctorInfoFuture = _loadDoctorInfo();
  }

  @override
  void dispose() {
    _doctorIdController.dispose();
    super.dispose();
  }

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
                  _buildDoctorInfoPanel(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('CHỌN NGÀY ĐĂNG KÝ'),
                  const SizedBox(height: 16),
                  _buildDateStrip(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('CA TRỰC TRONG NGÀY'),
                  const SizedBox(height: 16),
                  _buildShiftSlot(
                    'Sáng',
                    '07:30 - 11:30',
                    Icons.wb_sunny_rounded,
                    const Color(0xFFD97706),
                    '2/3',
                  ),
                  _buildShiftSlot(
                    'Chiều',
                    '13:00 - 17:00',
                    Icons.wb_twilight_rounded,
                    const Color(0xFF0E47B5),
                    '1/3',
                  ),
                  _buildShiftSlot(
                    'Tối',
                    '18:00 - 22:00',
                    Icons.nightlight_round_sharp,
                    const Color(0xFF15233D),
                    '0/3',
                  ),
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
      title: const Text(
        'Đăng ký ca trực',
        style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
      ),
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

  Widget _buildDoctorInfoPanel() {
    return FutureBuilder<_DoctorShiftInfo?>(
      future: _doctorInfoFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final doctor = snapshot.data;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F0FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Color(0xFF0E47B5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoading
                              ? 'Đang tải thông tin bác sĩ...'
                              : doctor?.name ?? 'Chưa xác định bác sĩ',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF15233D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor == null
                              ? 'Nhập Doctor ID nếu tài khoản chưa được liên kết.'
                              : '${doctor.departmentName} • ${doctor.specialization}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5A6680),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _doctorIdController,
                enabled: !isLoading,
                decoration: InputDecoration(
                  hintText: doctor?.doctorId ?? 'Nhập Doctor ID hoặc mã bác sĩ',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  suffixIcon: IconButton(
                    tooltip: 'Tải thông tin bác sĩ',
                    onPressed: isLoading ? null : _reloadDoctorInfoFromInput,
                    icon: const Icon(Icons.search_rounded),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF0E47B5)),
                  ),
                ),
                onSubmitted: (_) => _reloadDoctorInfoFromInput(),
              ),
              if (doctor != null) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDoctorTag('ID: ${doctor.doctorId}'),
                    if (doctor.doctorCode.isNotEmpty)
                      _buildDoctorTag('Mã: ${doctor.doctorCode}'),
                    _buildDoctorTag(
                      doctor.isActive ? 'Đang hoạt động' : 'Tạm khóa',
                      color: doctor.isActive
                          ? const Color(0xFF0E9F6E)
                          : const Color(0xFFD97706),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDoctorTag(
    String label, {
    Color color = const Color(0xFF0E47B5),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  void _reloadDoctorInfoFromInput() {
    final value = _doctorIdController.text.trim();
    setState(() {
      _selectedDoctorId = value.isEmpty ? null : value;
      _doctorInfoFuture = _loadDoctorInfo();
    });
  }

  Future<_DoctorShiftInfo?> _loadDoctorInfo() async {
    final firestore = FirebaseFirestore.instance;
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    final inputId = _selectedDoctorId?.trim();

    DocumentSnapshot<Map<String, dynamic>>? doctorDoc;
    if (inputId != null && inputId.isNotEmpty) {
      doctorDoc = await firestore.collection('Doctors').doc(inputId).get();
      if (!doctorDoc.exists) {
        final byCode = await firestore
            .collection('Doctors')
            .where('doctorCode', isEqualTo: inputId)
            .limit(1)
            .get();
        if (byCode.docs.isNotEmpty) {
          doctorDoc = byCode.docs.first;
        }
      }
    }

    if ((doctorDoc == null || !doctorDoc.exists) && authUid != null) {
      final byUser = await firestore
          .collection('Doctors')
          .where('userId', isEqualTo: authUid)
          .limit(1)
          .get();
      if (byUser.docs.isNotEmpty) {
        doctorDoc = byUser.docs.first;
      } else {
        doctorDoc = await firestore.collection('Doctors').doc(authUid).get();
      }
    }

    if (doctorDoc == null || !doctorDoc.exists) return null;

    final doctorData = doctorDoc.data() ?? {};
    final userId = (doctorData['userId'] ?? '').toString();
    final userData = userId.isEmpty ? null : await _loadUserData(userId);
    final departmentId = (doctorData['departmentId'] ?? '').toString();
    final departmentName = await _loadDepartmentName(departmentId);

    return _DoctorShiftInfo(
      doctorId: doctorDoc.id,
      doctorCode: (doctorData['doctorCode'] ?? '').toString(),
      name: _firstNonEmpty([
        doctorData['name'],
        doctorData['fullName'],
        doctorData['doctorName'],
        userData?['fullName'],
        userData?['username'],
      ], fallback: 'Bác sĩ ${doctorDoc.id}'),
      specialization: _firstNonEmpty([
        doctorData['specialization'],
        doctorData['specialty'],
        departmentName,
      ], fallback: 'Chưa cập nhật chuyên khoa'),
      departmentName: _firstNonEmpty([
        doctorData['departmentName'],
        departmentName,
        departmentId,
      ], fallback: 'Chưa cập nhật khoa'),
      isActive: doctorData['isActive'] != false,
    );
  }

  Future<Map<String, dynamic>?> _loadUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final lower = await firestore.collection('users').doc(uid).get();
    if (lower.exists) return lower.data();

    final upper = await firestore.collection('users').doc(uid).get();
    if (upper.exists) return upper.data();

    return null;
  }

  Future<String> _loadDepartmentName(String departmentId) async {
    if (departmentId.isEmpty) return '';

    final doc = await FirebaseFirestore.instance
        .collection('Departments')
        .doc(departmentId)
        .get();
    final data = doc.data();
    if (data == null) return '';

    return _firstNonEmpty([
      data['departmentName'],
      data['name'],
      data['title'],
    ]);
  }

  String _firstNonEmpty(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
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
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0E47B5).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekday(date.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white70
                          : const Color(0xFF8A95AC),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
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

  Widget _buildShiftSlot(
    String type,
    String time,
    IconData icon,
    Color color,
    String capacity,
  ) {
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
          color: isRegistered ? color.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRegistered ? color : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
                color: color.withValues(alpha: 0.12),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15233D),
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5A6680),
                    ),
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A95AC),
                  ),
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
            color: const Color(0xFF0E47B5).withValues(alpha: 0.3),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'XÁC NHẬN ĐĂNG KÝ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  String _getWeekday(int day) {
    switch (day) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }
}

class _DoctorShiftInfo {
  const _DoctorShiftInfo({
    required this.doctorId,
    required this.doctorCode,
    required this.name,
    required this.specialization,
    required this.departmentName,
    required this.isActive,
  });

  final String doctorId;
  final String doctorCode;
  final String name;
  final String specialization;
  final String departmentName;
  final bool isActive;
}
