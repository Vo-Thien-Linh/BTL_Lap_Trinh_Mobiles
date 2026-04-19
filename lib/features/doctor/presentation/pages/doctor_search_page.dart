import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class DoctorSearchPage extends StatefulWidget {
  const DoctorSearchPage({super.key});

  @override
  State<DoctorSearchPage> createState() => _DoctorSearchPageState();
}

class _DoctorSearchPageState extends State<DoctorSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';

  // Data Collections
  final List<Map<String, dynamic>> _allPatients = [
    {'name': 'Nguyễn Văn Anh', 'id': 'BN10293', 'status': 'Đang chờ', 'color': Colors.blue, 'type': 'patient'},
    {'name': 'Trần Thị Bảo', 'id': 'BN10294', 'status': 'Hoàn tất', 'color': Colors.green, 'type': 'patient'},
    {'name': 'Lê Hoàng Cường', 'id': 'BN10295', 'status': 'Khẩn cấp', 'color': Colors.red, 'type': 'patient'},
    {'name': 'Phạm Thị Diễm', 'id': 'BN10296', 'status': 'Đang khám', 'color': Colors.orange, 'type': 'patient'},
    {'name': 'Vũ Hoàng Nam', 'id': 'BN10297', 'status': 'Đang chờ', 'color': Colors.blue, 'type': 'patient'},
  ];

  final List<Map<String, dynamic>> _allMeds = [
    {'name': 'Amoxicillin 500mg', 'category': 'Kháng sinh', 'info': 'Còn 200 viên', 'type': 'medicine'},
    {'name': 'Paracetamol 500mg', 'category': 'Giảm đau', 'info': 'Còn 500 viên', 'type': 'medicine'},
    {'name': 'Ibuprofen 400mg', 'category': 'Kháng viêm', 'info': 'Hết hàng', 'type': 'medicine'},
    {'name': 'Ceftriaxone 1g', 'category': 'Kháng sinh tiêm', 'info': 'Còn 50 ống', 'type': 'medicine'},
  ];

  final List<Map<String, dynamic>> _allICD = [
    {'code': 'I10', 'name': 'Tăng huyết áp vô căn', 'type': 'icd'},
    {'code': 'E11', 'name': 'Đái tháo đường típ 2', 'type': 'icd'},
    {'code': 'J00', 'name': 'Viêm mũi họng cấp tính', 'type': 'icd'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    // Auto-focus logic
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF202637), size: 20),
        ),
        title: Hero(
          tag: 'doctor_search_bar',
          child: Material(
            color: Colors.transparent,
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF131826)),
              decoration: const InputDecoration(
                hintText: 'Tìm bệnh nhân, thuốc, mã ICD...',
                hintStyle: TextStyle(color: Color(0xFF8B92A6), fontWeight: FontWeight.bold, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: () => _searchController.clear(),
              icon: const Icon(Icons.close_rounded, color: Color(0xFF8B92A6)),
            ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F4F9)),
          Expanded(
            child: _searchQuery.isEmpty ? _buildSuggestions() : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BÁC SĨ THƯỜNG DÙNG',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF8B92A6), letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _searchChip('Bệnh nhân mới', Icons.person_add_rounded),
              _searchChip('Đơn thuốc mẫu', Icons.description_rounded),
              _searchChip('Tra cứu ICD-10', Icons.biotech_rounded),
              _searchChip('Lịch trực', Icons.calendar_today_rounded),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'HỒ SƠ VỪA XỬ LÝ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF8B92A6), letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          _suggestionItem('Nguyễn Văn Anh', 'Cấp thuốc - 14:00', Icons.history_rounded),
          _suggestionItem('Lê Hoàng Cường', 'Chờ kết quả XN', Icons.history_rounded),
        ],
      ),
    );
  }

  Widget _searchChip(String label, IconData icon) {
    return ActionChip(
      onPressed: () => _searchController.text = label,
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE8EBF4)),
      ),
      labelStyle: const TextStyle(color: Color(0xFF131826), fontWeight: FontWeight.w600, fontSize: 13),
    );
  }

  Widget _suggestionItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF131826))),
                Text(subtitle, style: const TextStyle(color: Color(0xFF8B92A6), fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final List<Map<String, dynamic>> patients = _allPatients.where((p) => p['name'].toString().toLowerCase().contains(_searchQuery)).toList();
    final List<Map<String, dynamic>> meds = _allMeds.where((m) => m['name'].toString().toLowerCase().contains(_searchQuery)).toList();
    final List<Map<String, dynamic>> icds = _allICD.where((i) => i['name'].toString().toLowerCase().contains(_searchQuery) || i['code'].toString().toLowerCase().contains(_searchQuery)).toList();

    if (patients.isEmpty && meds.isEmpty && icds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Không thấy thông tin phù hợp', style: TextStyle(color: Color(0xFF8B92A6), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (patients.isNotEmpty) ...[
          _buildSectionHeader('BỆNH NHÂN'),
          ...patients.map((p) => _resultItem(p['name'] as String, 'Mã BN: ${p['id']}', Icons.person_rounded, p['color'] as Color)),
          const SizedBox(height: 20),
        ],
        if (meds.isNotEmpty) ...[
          _buildSectionHeader('KHO THUỐC'),
          ...meds.map((m) => _resultItem(m['name'] as String, '${m['category']} - ${m['info']}', Icons.medication_rounded, Colors.indigo)),
          const SizedBox(height: 20),
        ],
        if (icds.isNotEmpty) ...[
          _buildSectionHeader('MÃ BỆNH ICD-10'),
          ...icds.map((i) => _resultItem(i['name'] as String, 'Mã ICD: ${i['code']}', Icons.biotech_rounded, Colors.teal)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8B92A6), letterSpacing: 1.0),
      ),
    );
  }

  Widget _resultItem(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F4F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF131826))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF5C6477), fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFD7DCE6)),
        ],
      ),
    );
  }
}
