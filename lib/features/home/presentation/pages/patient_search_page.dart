import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../appointment/data/models/appointment_models.dart';
import '../../../appointment/domain/entities/appointment_entities.dart';
import '../utils/department_visuals.dart';
import '../widgets/doctor_profile_sheet.dart';
import 'department_detail_page.dart';

class PatientSearchPage extends StatefulWidget {
  const PatientSearchPage({super.key});

  @override
  State<PatientSearchPage> createState() => _PatientSearchPageState();
}

class _PatientSearchPageState extends State<PatientSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';

  List<DoctorEntity> _allDoctors = [];
  List<DepartmentEntity> _allDepartments = [];
  bool _isLoadingData = true;

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
    _loadFirebaseData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFirebaseData() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Load departments
      final deptsSnapshot = await firestore.collection('Departments').get();
      final depts = deptsSnapshot.docs
          .map(DepartmentModel.fromFirestore)
          .toList();

      // Load doctors
      final docsSnapshot = await firestore.collection('Doctors').get();
      final docs = docsSnapshot.docs.map(DoctorModel.fromFirestore).toList();

      if (mounted) {
        setState(() {
          _allDepartments = depts;
          _allDoctors = docs;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading search data: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF202637),
            size: 20,
          ),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF131826),
          ),
          decoration: const InputDecoration(
            hintText: 'Tìm bác sĩ, chuyên khoa...',
            hintStyle: TextStyle(
              color: Color(0xFF8B92A6),
              fontWeight: FontWeight.w400,
            ),
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
            child: _searchQuery.isEmpty
                ? _buildSuggestions()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    final suggestedDoctors = _allDoctors.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TÌM KIẾM PHỔ BIẾN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8B92A6),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              _searchChip('Nhi khoa'),
              _searchChip('Tim mạch'),
              _searchChip('Da liễu'),
              _searchChip('Xét nghiệm'),
              _searchChip('Nội tổng quát'),
            ],
          ),
          const SizedBox(height: 32),
          if (suggestedDoctors.isNotEmpty) ...[
            const Text(
              'BÁC SĨ GỢI Ý',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8B92A6),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            ...suggestedDoctors.map((doctor) => _suggestionDoctor(doctor)),
          ],
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
      labelStyle: const TextStyle(
        color: Color(0xFF131826),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  Widget _suggestionDoctor(DoctorEntity doctor) {
    final deptVisual = departmentVisualFromParts(
      id: doctor.departmentId,
      name: doctor.departmentName,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final dept = _allDepartments.firstWhere(
              (d) => d.id == doctor.departmentId,
              orElse: () => DepartmentEntity(
                id: doctor.departmentId,
                name: doctor.departmentName,
                description: '',
                location: '',
                phone: '',
              ),
            );
            DoctorProfileSheet.show(context, doctor, dept, deptVisual.colors);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF0F4FF),
                  backgroundImage: doctor.imageUrl != null
                      ? NetworkImage(doctor.imageUrl!)
                      : null,
                  child: doctor.imageUrl == null
                      ? const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF0E47B5),
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: Color(0xFF131826),
                        ),
                      ),
                      Text(
                        doctor.specialization.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF8B92A6),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    final query = _searchQuery.trim().toLowerCase();

    final matchedDoctors = _allDoctors.where((doctor) {
      return doctor.name.toLowerCase().contains(query) ||
          doctor.specialization.toLowerCase().contains(query) ||
          doctor.departmentName.toLowerCase().contains(query);
    }).toList();

    final matchedDepts = _allDepartments.where((dept) {
      return dept.name.toLowerCase().contains(query) ||
          dept.location.toLowerCase().contains(query) ||
          dept.description.toLowerCase().contains(query);
    }).toList();

    if (matchedDoctors.isEmpty && matchedDepts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy bác sĩ hoặc chuyên khoa nào',
              style: TextStyle(
                color: Color(0xFF5C6477),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (matchedDoctors.isNotEmpty) ...[
          const Text(
            'BÁC SĨ TÌM THẤY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8B92A6),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ...matchedDoctors.map((doctor) {
            final deptVisual = departmentVisualFromParts(
              id: doctor.departmentId,
              name: doctor.departmentName,
            );
            return _resultItem(
              doctor.name,
              '${doctor.specialization} - ${doctor.departmentName}',
              Icons.person_rounded,
              imageUrl: doctor.imageUrl,
              onTap: () {
                final dept = _allDepartments.firstWhere(
                  (d) => d.id == doctor.departmentId,
                  orElse: () => DepartmentEntity(
                    id: doctor.departmentId,
                    name: doctor.departmentName,
                    description: '',
                    location: '',
                    phone: '',
                  ),
                );
                DoctorProfileSheet.show(
                  context,
                  doctor,
                  dept,
                  deptVisual.colors,
                );
              },
            );
          }),
          const SizedBox(height: 20),
        ],
        if (matchedDepts.isNotEmpty) ...[
          const Text(
            'CHUYÊN KHOA TÌM THẤY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8B92A6),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ...matchedDepts.map((dept) {
            final deptVisual = departmentVisualFor(dept);
            return _resultItem(
              dept.name,
              dept.location.isNotEmpty ? dept.location : dept.description,
              deptVisual.icon,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DepartmentDetailPage(
                      department: dept,
                      icon: deptVisual.icon,
                      colors: deptVisual.colors,
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ],
    );
  }

  Widget _resultItem(
    String title,
    String subtitle,
    IconData icon, {
    String? imageUrl,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F4F9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(imageUrl, fit: BoxFit.cover),
                        )
                      : Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF131826),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF5C6477),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFD7DCE6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
