import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class PatientSearchPage extends StatefulWidget {
  const PatientSearchPage({super.key});

  @override
  State<PatientSearchPage> createState() => _PatientSearchPageState();
}

class _PatientSearchPageState extends State<PatientSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    // Auto-focus the search field when entering
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
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF131826)),
          decoration: const InputDecoration(
            hintText: 'Tìm bác sĩ, chuyên khoa...',
            hintStyle: TextStyle(color: Color(0xFF8B92A6), fontWeight: FontWeight.w400),
            border: InputBorder.none,
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
            'TÌM KIẾM PHỔ BIẾN',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF8B92A6), letterSpacing: 1.0),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              _searchChip('Nhi khoa'),
              _searchChip('Tim mạch'),
              _searchChip('Da liễu'),
              _searchChip('Xét nghiệm máu'),
              _searchChip('Khám tổng quát'),
              _searchChip('Nội soi'),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'BÁC SĨ GỢI Ý',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF8B92A6), letterSpacing: 1.0),
          ),
          const SizedBox(height: 16),
          _suggestionDoctor('BS. Nguyễn Minh Đức', 'TIM MẠCH'),
          _suggestionDoctor('BS. Trần Thu Hà', 'NHI KHOA'),
          _suggestionDoctor('BS. Lê Quang Vinh', 'XÉT NGHIỆM'),
        ],
      ),
    );
  }

  Widget _searchChip(String label) {
    return ActionChip(
      onPressed: () => _searchController.text = label,
      label: Text(label),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE8EBF4)),
      ),
      labelStyle: const TextStyle(color: Color(0xFF131826), fontWeight: FontWeight.w600, fontSize: 13),
    );
  }

  Widget _suggestionDoctor(String name, String specialty) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFF0F4FF),
            child: Icon(Icons.person_outline_rounded, color: Color(0xFF0E47B5), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF131826))),
                Text(specialty, style: const TextStyle(color: Color(0xFF8B92A6), fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // Basic mock filtering
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _resultItem('Bác sĩ Vũ Trường Phi', 'Nội tổng quát', Icons.person_search_rounded),
        _resultItem('Khoa Tim mạch', 'Tầng 2 - Khu A', Icons.domain_rounded),
        _resultItem('Xét nghiệm tổng quát', 'Dịch vụ y tế', Icons.analytics_rounded),
      ],
    );
  }

  Widget _resultItem(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F4F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.primary, size: 24),
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
