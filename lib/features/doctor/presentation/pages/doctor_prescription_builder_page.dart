import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'doctor_invoice_page.dart';

class DoctorPrescriptionBuilderPage extends StatefulWidget {
  final Map<String, dynamic>? patientData;
  final String? appointmentId;

  const DoctorPrescriptionBuilderPage({
    super.key,
    this.patientData,
    this.appointmentId,
  });

  @override
  State<DoctorPrescriptionBuilderPage> createState() =>
      _DoctorPrescriptionBuilderPageState();
}

class _DoctorPrescriptionBuilderPageState
    extends State<DoctorPrescriptionBuilderPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _templates = [
    {
      'title': 'Sốt xuất huyết',
      'desc': 'Kê đơn tiêu chuẩn',
      'medsCount': 3,
      'color': Colors.redAccent,
    },
    {
      'title': 'Viêm họng cấp',
      'desc': 'Kháng sinh + Giảm đau',
      'medsCount': 4,
      'color': Colors.blueAccent,
    },
    {
      'title': 'Đau dạ dày',
      'desc': 'Bảo vệ niêm mạc',
      'medsCount': 2,
      'color': const Color(0xFF10B981),
    },
  ];

  final List<Map<String, dynamic>> _defaultDrugCatalog = [
    {
      'name': 'Amoxicillin',
      'unit': 'Viên',
      'strength': '500mg',
      'category': 'Kháng sinh',
      'price': 1500,
    },
    {
      'name': 'Paracetamol',
      'unit': 'Viên',
      'strength': '500mg',
      'category': 'Giảm đau',
      'price': 500,
    },
    {
      'name': 'Ibuprofen',
      'unit': 'Viên',
      'strength': '400mg',
      'category': 'Kháng viêm',
      'price': 1200,
    },
    {
      'name': 'Omeprazole',
      'unit': 'Viên',
      'strength': '20mg',
      'category': 'Dạ dày',
      'price': 2500,
    },
    {
      'name': 'Amlodipine',
      'unit': 'Viên',
      'strength': '5mg',
      'category': 'Huyết áp',
      'price': 3000,
    },
    {
      'name': 'Metformin',
      'unit': 'Viên',
      'strength': '850mg',
      'category': 'Tiểu đường',
      'price': 2000,
    },
  ];

  final List<Map<String, dynamic>> _selectedMeds = [];
  String _activeCategory = 'Tất cả';

  Map<String, dynamic>? _selectedPatientData;
  String? _selectedAppointmentId;

  @override
  void initState() {
    super.initState();
    _selectedPatientData = widget.patientData;
    _selectedAppointmentId = widget.appointmentId;
  }

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    double total = 350000; // Starting with Exam fee as in the sample image
    for (var med in _selectedMeds) {
      total += (med['quantity'] ?? 0) * (med['price'] ?? 0);
    }
    return total;
  }

  String get _patientId {
    final data = _selectedPatientData ?? const <String, dynamic>{};
    return (data['patientId'] ??
            data['userId'] ??
            data['uid'] ??
            data['id'] ??
            '')
        .toString()
        .trim();
  }

  String get _patientName {
    final data = _selectedPatientData ?? const <String, dynamic>{};
    final name = (data['patientName'] ?? data['fullName'] ?? data['name'] ?? '')
        .toString()
        .trim();
    return name.isEmpty ? 'Chưa xác định bệnh nhân' : name;
  }

  bool get _hasPatientContext => _patientId.isNotEmpty;

  Map<String, dynamic>? get _effectivePatientData => _selectedPatientData;

  String? get _effectiveAppointmentId => _selectedAppointmentId;

  void _showAddMedicineModal(Map<String, dynamic> med) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DosingConfigModal(
        medicine: med,
        onConfirm: (config) {
          setState(() {
            _selectedMeds.add({...med, ...config});
          });
        },
      ),
    );
  }

  void _showEditMedicineModal(int index, Map<String, dynamic> med) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DosingConfigModal(
        medicine: med,
        initialConfig: med,
        confirmLabel: 'Cập nhật',
        onConfirm: (config) {
          setState(() {
            _selectedMeds[index] = {...med, ...config};
          });
        },
      ),
    );
  }

  void _showCustomMedicineModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomMedicineModal(
        initialName: _searchController.text.trim(),
        onConfirm: (medicine) async {
          final savedMedicine = await _saveMedicineToFirebase(medicine);
          if (!mounted) return;
          setState(() {
            _searchController.clear();
            _searchQuery = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã thêm thuốc ${savedMedicine['name']} vào Firebase',
              ),
            ),
          );
          Future.delayed(const Duration(milliseconds: 250), () {
            if (!mounted) return;
            _showAddMedicineModal(savedMedicine);
          });
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _saveMedicineToFirebase(
    Map<String, dynamic> medicine,
  ) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final doctorId = await _resolveCurrentDoctorId();
    final payload = {
      ...medicine,
      'doctorId': doctorId,
      'createdByUserId': currentUserId,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final doc = await FirebaseFirestore.instance
        .collection('Medicines')
        .add(payload);
    return {...medicine, 'medicineId': doc.id, 'id': doc.id};
  }

  Future<String?> _resolveCurrentDoctorId() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return null;
    final snapshot = await FirebaseFirestore.instance
        .collection('Doctors')
        .where('userId', isEqualTo: currentUserId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return currentUserId;
    return snapshot.docs.first.id;
  }

  void _applyTemplate(Map<String, dynamic> template) {
    // Mock: Adding 3 predefined meds
    setState(() {
      _selectedMeds.addAll([
        {
          'name': 'Paracetamol',
          'strength': '500mg',
          'unit': 'Viên',
          'quantity': 10,
          'morning': 1,
          'noon': 1,
          'evening': 1,
          'timing': 'Sau ăn',
          'duration': 3,
        },
        {
          'name': 'Amoxicillin',
          'strength': '500mg',
          'unit': 'Viên',
          'quantity': 14,
          'morning': 1,
          'noon': 0,
          'evening': 1,
          'timing': 'Sau ăn',
          'duration': 7,
        },
      ]);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã áp dụng phác đồ ${template['title']}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        title: const Text(
          'Kê đơn thuốc',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: const Color(
          0xFF7C3AED,
        ), // Distinctive Purple for Prescriptions
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTopSearch(),
          _buildPatientBanner(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTemplateSection(),
                  _buildCatalogSection(),
                  _buildPrescriptionSummary(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _selectedMeds.isNotEmpty ? _buildConfirmBar() : null,
    );
  }

  Widget _buildTopSearch() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF7C3AED),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Tìm nhanh tên thuốc...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white70,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: _showCustomMedicineModal,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF7C3AED),
              fixedSize: const Size(48, 48),
            ),
            tooltip: 'Thêm thuốc mới',
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientBanner() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return const SizedBox.shrink();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('Doctors')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get(),
      builder: (context, doctorSnapshot) {
        var doctorId = currentUserId;
        if (doctorSnapshot.hasData && doctorSnapshot.data!.docs.isNotEmpty) {
          doctorId = doctorSnapshot.data!.docs.first.id;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Appointments')
              .where('doctorId', isEqualTo: doctorId)
              .where(
                'status',
                whereIn: ['calling', 'ongoing', 'waiting_payment', 'completed'],
              )
              .snapshots(),
          builder: (context, snapshot) {
            final items = <Map<String, dynamic>>[];
            for (final doc in snapshot.data?.docs ?? const []) {
              final data = doc.data() as Map<String, dynamic>;
              final appointmentDate = data['appointmentDate'];
              if (appointmentDate is Timestamp &&
                  !_isSameDate(appointmentDate.toDate(), DateTime.now())) {
                continue;
              }
              items.add({...data, 'appointmentId': doc.id});
            }

            if (_selectedAppointmentId != null &&
                _selectedPatientData != null &&
                !items.any(
                  (item) => item['appointmentId'] == _selectedAppointmentId,
                )) {
              items.insert(0, {
                ..._selectedPatientData!,
                'appointmentId': _selectedAppointmentId,
              });
            }

            items.sort((a, b) {
              final dateA = a['appointmentDate'];
              final dateB = b['appointmentDate'];
              if (dateA is Timestamp && dateB is Timestamp) {
                return dateB.toDate().compareTo(dateA.toDate());
              }
              return 0;
            });

            final selectedValue =
                items.any(
                  (item) => item['appointmentId'] == _selectedAppointmentId,
                )
                ? _selectedAppointmentId
                : null;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDDE6F7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn bệnh nhân để kê đơn',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15233D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedValue,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.assignment_ind_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDDE6F7)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    hint: const Text('Bệnh nhân đang khám tại bác sĩ'),
                    items: items.map((item) {
                      final appointmentId =
                          item['appointmentId']?.toString() ?? '';
                      final patientName =
                          (item['patientName'] ??
                                  item['fullName'] ??
                                  item['name'] ??
                                  'Bệnh nhân')
                              .toString();
                      final queueNumber =
                          item['queueNumber']?.toString() ?? '-';
                      final status = item['status']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: appointmentId,
                        child: Text(
                          '$patientName - STT $queueNumber - ${_formatAppointmentStatus(status)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (appointmentId) {
                      if (appointmentId == null) return;
                      final selected = items.firstWhere(
                        (item) => item['appointmentId'] == appointmentId,
                      );
                      setState(() {
                        _selectedAppointmentId = appointmentId;
                        _selectedPatientData = selected;
                      });
                    },
                  ),
                  if (items.isEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Chưa có bệnh nhân đang khám/chờ thanh toán để kê đơn.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A95AC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatAppointmentStatus(String status) {
    switch (status) {
      case 'calling':
        return 'Đang gọi';
      case 'ongoing':
        return 'Đang khám';
      case 'waiting_payment':
        return 'Chờ thanh toán';
      case 'completed':
        return 'Hoàn tất';
      default:
        return status;
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 24, bottom: 16),
          child: Text(
            'PHÁC ĐỒ MẪU',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF8A95AC),
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final t = _templates[index];
              return GestureDetector(
                onTap: () => _applyTemplate(t),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (t['color'] as Color),
                        (t['color'] as Color).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${t['medsCount']} loại thuốc',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogSection() {
    final categories = [
      'Tất cả',
      'Kháng sinh',
      'Giảm đau',
      'Kháng viêm',
      'Dạ dày',
      'Huyết áp',
      'Tiểu đường',
      'Khác',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 24, bottom: 16),
          child: Text(
            'DANH MỤC THUỐC',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF8A95AC),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: categories.map((c) {
              final isSelected = _activeCategory == c;
              return GestureDetector(
                onTap: () => setState(() => _activeCategory = c),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : const Color(0xFFDDE6F7),
                    ),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF5A6680),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Medicines')
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            final firebaseMeds = (snapshot.data?.docs ?? const []).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {...data, 'medicineId': doc.id, 'id': doc.id};
            }).toList();
            final filteredMeds = _filterMedicines([
              ..._defaultDrugCatalog,
              ...firebaseMeds,
            ]);

            if (snapshot.connectionState == ConnectionState.waiting &&
                filteredMeds.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (filteredMeds.isEmpty) return _buildNoMedicineFound();

            return ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredMeds.length,
              itemBuilder: (context, index) {
                final med = filteredMeds[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    med['name']?.toString() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15233D),
                    ),
                  ),
                  subtitle: Text(
                    _medicineSubtitle(med),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A95AC),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFF7C3AED),
                  ),
                  onTap: () => _showAddMedicineModal(med),
                );
              },
            );
          },
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filterMedicines(List<Map<String, dynamic>> meds) {
    final normalizedQuery = _searchQuery.toLowerCase();
    return meds.where((med) {
      final category = med['category']?.toString() ?? '';
      final matchesCategory =
          _activeCategory == 'Tất cả' || category == _activeCategory;
      final searchable = [
        med['name'],
        med['strength'],
        med['category'],
        med['unit'],
      ].whereType<Object>().join(' ').toLowerCase();
      final matchesSearch =
          normalizedQuery.isEmpty || searchable.contains(normalizedQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Widget _buildNoMedicineFound() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6F7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.medication_liquid_rounded, color: Color(0xFF7C3AED)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Không tìm thấy thuốc. Bác sĩ có thể thêm thuốc mới vào đơn.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A6680),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _showCustomMedicineModal,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  String _medicineSubtitle(Map<String, dynamic> med) {
    final base =
        '${med['strength']} | ${med['category']} | ${med['price']}đ/${med['unit']}';
    final stock = int.tryParse(med['stockQuantity']?.toString() ?? '');
    if (stock == null) return base;
    return '$base | Còn $stock ${med['unit']}';
  }

  Widget _buildPrescriptionSummary() {
    if (_selectedMeds.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 32, bottom: 16),
          child: Text(
            'ĐƠN THUỐC ĐÃ KÊ',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF8A95AC),
            ),
          ),
        ),
        ..._selectedMeds.asMap().entries.map((entry) {
          final med = entry.value;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(width: 6, color: const Color(0xFF7C3AED)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  med['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Color(0xFF15233D),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Sửa thuốc',
                                      onPressed: () => _showEditMedicineModal(
                                        entry.key,
                                        med,
                                      ),
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        size: 18,
                                        color: Color(0xFF7C3AED),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Xóa thuốc',
                                      onPressed: () => setState(
                                        () => _selectedMeds.removeAt(entry.key),
                                      ),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Color(0xFFD1D5DB),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              '${med['strength']} | ${med['price']}đ x ${med['quantity']} = ${((med['price'] ?? 0) * (med['quantity'] ?? 0))}đ',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5A6680),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _dosageItem('S', med['morning']),
                                _dosageItem('T', med['noon']),
                                _dosageItem('C', med['evening']),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F6FC),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    med['timing'],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _dosageItem(String label, int val) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: val > 0 ? const Color(0xFFE8F1FF) : const Color(0xFFF3F6FC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $val',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: val > 0 ? const Color(0xFF1457CC) : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildConfirmBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TỔNG THANH TOÁN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8A95AC),
                  ),
                ),
                Text(
                  '${_totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (!_hasPatientContext) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Không thể kê đơn vì chưa xác định bệnh nhân.',
                    ),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorInvoicePage(
                    selectedMeds: _selectedMeds,
                    totalPrice: _totalPrice,
                    patientData: _effectivePatientData,
                    appointmentId: _effectiveAppointmentId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'XÁC NHẬN ĐƠN',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomMedicineModal extends StatefulWidget {
  final String initialName;
  final Future<void> Function(Map<String, dynamic>) onConfirm;

  const _CustomMedicineModal({
    required this.initialName,
    required this.onConfirm,
  });

  @override
  State<_CustomMedicineModal> createState() => _CustomMedicineModalState();
}

class _CustomMedicineModalState extends State<_CustomMedicineModal> {
  late final TextEditingController _nameController;
  final TextEditingController _strengthController = TextEditingController();
  final TextEditingController _unitController = TextEditingController(
    text: 'Viên',
  );
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  String _category = 'Khác';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên thuốc')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onConfirm({
        'name': name,
        'strength': _strengthController.text.trim(),
        'unit': _unitController.text.trim().isEmpty
            ? 'Viên'
            : _unitController.text.trim(),
        'category': _category,
        'price': int.tryParse(_priceController.text.trim()) ?? 0,
        'stockQuantity': int.tryParse(_stockController.text.trim()) ?? 0,
        'isCustom': true,
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu thuốc vào Firebase: $error')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Thêm thuốc mới',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15233D),
                ),
              ),
              const SizedBox(height: 20),
              _input(_nameController, 'Tên thuốc', Icons.medication_rounded),
              const SizedBox(height: 12),
              _input(
                _strengthController,
                'Hàm lượng, ví dụ 500mg',
                Icons.scale_rounded,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _input(
                      _unitController,
                      'Đơn vị',
                      Icons.category_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _input(
                      _priceController,
                      'Đơn giá',
                      Icons.payments_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _input(
                _stockController,
                'Số lượng hiện có',
                Icons.inventory_2_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text(
                'NHÓM THUỐC',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF8A95AC),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'Kháng sinh',
                      'Giảm đau',
                      'Kháng viêm',
                      'Dạ dày',
                      'Huyết áp',
                      'Tiểu đường',
                      'Khác',
                    ].map((category) {
                      final isSelected = _category == category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _category = category),
                        selectedColor: const Color(0xFF7C3AED),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF5A6680),
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(_isSaving ? 'ĐANG LƯU...' : 'THÊM VÀ KÊ THUỐC'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE6F7)),
        ),
      ),
    );
  }
}

class _DosingConfigModal extends StatefulWidget {
  final Map<String, dynamic> medicine;
  final Map<String, dynamic>? initialConfig;
  final String confirmLabel;
  final Function(Map<String, dynamic>) onConfirm;

  const _DosingConfigModal({
    required this.medicine,
    this.initialConfig,
    this.confirmLabel = 'Thêm',
    required this.onConfirm,
  });

  @override
  State<_DosingConfigModal> createState() => _DosingConfigModalState();
}

class _DosingConfigModalState extends State<_DosingConfigModal> {
  int _morning = 1, _noon = 0, _evening = 1, _duration = 7;
  int? _manualQty;
  String _timing = 'Sau ăn';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialConfig;
    if (initial == null) return;
    _morning = int.tryParse(initial['morning']?.toString() ?? '') ?? _morning;
    _noon = int.tryParse(initial['noon']?.toString() ?? '') ?? _noon;
    _evening = int.tryParse(initial['evening']?.toString() ?? '') ?? _evening;
    _duration =
        int.tryParse(initial['duration']?.toString() ?? '') ?? _duration;
    _manualQty = int.tryParse(initial['quantity']?.toString() ?? '');
    _timing = initial['timing']?.toString() ?? _timing;
  }

  @override
  Widget build(BuildContext context) {
    int total = _manualQty ?? (_morning + _noon + _evening) * _duration;
    final stockQuantity = int.tryParse(
      widget.medicine['stockQuantity']?.toString() ?? '',
    );

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.medicine['name'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF15233D),
            ),
          ),
          Text(
            '${widget.medicine['strength']} | ${widget.medicine['category']}',
            style: const TextStyle(color: Color(0xFF8A95AC), fontSize: 13),
          ),
          if (stockQuantity != null) ...[
            const SizedBox(height: 8),
            Text(
              'Số lượng hiện có: $stockQuantity ${widget.medicine['unit']}',
              style: const TextStyle(
                color: Color(0xFF0E9F6E),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 30),
          const Text(
            'LIỀU DÙNG (VIÊN)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF8A95AC),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _counter('Sáng', _morning, (v) => setState(() => _morning = v)),
              _counter('Trưa', _noon, (v) => setState(() => _noon = v)),
              _counter('Tối', _evening, (v) => setState(() => _evening = v)),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'THỜI ĐIỂM UỐNG',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF8A95AC),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: ['Trước ăn', 'Sau ăn', 'Khi đói', 'Trước đi ngủ'].map((
              t,
            ) {
              final isSelected = _timing == t;
              return GestureDetector(
                onTap: () => setState(() => _timing = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFFF3F6FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF5A6680),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Số lượng tổng:',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15233D),
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7C3AED),
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: '$total',
                  ),
                  onChanged: (v) {
                    setState(() {
                      _manualQty = int.tryParse(v);
                    });
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 40),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thành tiền: ${(total * (widget.medicine['price'] ?? 0)).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF15233D),
                      ),
                    ),
                    const Text(
                      'Đã bao gồm thuế GTGT',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF0E9F6E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (stockQuantity != null && total > stockQuantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Số lượng kê ($total) vượt số lượng hiện có ($stockQuantity)',
                        ),
                      ),
                    );
                    return;
                  }
                  widget.onConfirm({
                    'morning': _morning,
                    'noon': _noon,
                    'evening': _evening,
                    'timing': _timing,
                    'duration': _duration,
                    'quantity': total,
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  widget.confirmLabel.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _counter(String label, int val, Function(int) onChanged) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A6680),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () => onChanged(val > 0 ? val - 1 : 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.remove, size: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '$val',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => onChanged(val + 1),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, size: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
