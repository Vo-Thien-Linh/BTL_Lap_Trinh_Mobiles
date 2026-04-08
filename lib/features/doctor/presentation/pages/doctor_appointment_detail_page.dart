import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorAppointmentDetailPage extends StatefulWidget {
  const DoctorAppointmentDetailPage({
    super.key,
    required this.appointmentId,
    required this.initialData,
  });

  final String appointmentId;
  final Map<String, dynamic> initialData;

  @override
  State<DoctorAppointmentDetailPage> createState() =>
      _DoctorAppointmentDetailPageState();
}

class _DoctorAppointmentDetailPageState extends State<DoctorAppointmentDetailPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _examController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _adviceController = TextEditingController();

  late final TabController _tabController;
  final List<_MedicineFormData> _medicines = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _hydrateFromInitialData();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _examController.dispose();
    _diagnosisController.dispose();
    _adviceController.dispose();
    _tabController.dispose();
    for (final medicine in _medicines) {
      medicine.dispose();
    }
    super.dispose();
  }

  void _hydrateFromInitialData() {
    _symptomsController.text =
        (widget.initialData['symptoms'] ?? '').toString();
    _examController.text =
        (widget.initialData['examinationNotes'] ?? '').toString();
    _diagnosisController.text =
        (widget.initialData['diagnosis'] ?? '').toString();
    _adviceController.text =
        (widget.initialData['doctorAdvice'] ?? '').toString();

    final rawMedicines = widget.initialData['prescription'];
    if (rawMedicines is List) {
      for (final item in rawMedicines) {
        if (item is Map<String, dynamic>) {
          _medicines.add(
            _MedicineFormData.fromMap(item),
          );
        }
      }
    }

    if (_medicines.isEmpty) {
      _medicines.add(_MedicineFormData.empty());
    }
  }

  Future<void> _saveDraft() async {
    await _persist(status: 'in_progress');
  }

  Future<void> _completeAppointment() async {
    final hasDiagnosis = _diagnosisController.text.trim().isNotEmpty;
    final hasPlan =
        _adviceController.text.trim().isNotEmpty || _validMedicines().isNotEmpty;

    if (!hasDiagnosis || !hasPlan) {
      _showSnackBar(
        'Cần nhập chẩn đoán và ít nhất dặn dò hoặc 1 thuốc trước khi hoàn tất.',
        isError: true,
      );
      return;
    }

    await _persist(status: 'completed');
  }

  Future<void> _cancelAppointment() async {
    await _persist(status: 'cancelled');
  }

  Future<void> _persist({required String status}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'symptoms': _symptomsController.text.trim(),
      'examinationNotes': _examController.text.trim(),
      'diagnosis': _diagnosisController.text.trim(),
      'doctorAdvice': _adviceController.text.trim(),
      'prescription': _validMedicines(),
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('Appointments')
          .doc(widget.appointmentId)
          .update(payload);

      if (!mounted) return;
      _showSnackBar(
        status == 'completed'
            ? 'Đã hoàn tất lịch khám.'
            : status == 'cancelled'
            ? 'Đã huỷ lịch khám.'
            : 'Đã lưu nháp.',
      );

      if (status == 'completed' || status == 'cancelled') {
        Navigator.pop(context);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Lưu thất bại. Vui lòng thử lại.', isError: true);
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  List<Map<String, String>> _validMedicines() {
    return _medicines
        .map((entry) => entry.toMap())
        .where((entry) => entry['name']!.trim().isNotEmpty)
        .toList();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFB3261E) : const Color(0xFF166534),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientName =
        (widget.initialData['patientName'] ?? 'Bệnh nhân').toString();
    final reason =
        (widget.initialData['reason'] ?? 'Khám tổng quát').toString();
    final date = (widget.initialData['appointmentDate'] as Timestamp?)?.toDate();
    final dateText = date == null
        ? 'Chưa có thời gian'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('Chi tiết khám bệnh'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0E47B5), Color(0xFF2A6ED6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: TextStyle(color: Colors.white.withOpacity(0.92)),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDF7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: const Color(0xFF0E47B5),
              unselectedLabelColor: const Color(0xFF5B6780),
              tabs: const [
                Tab(text: 'Tổng quan'),
                Tab(text: 'Chẩn đoán'),
                Tab(text: 'Đơn thuốc'),
                Tab(text: 'Dặn dò'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDiagnosisTab(),
                _buildMedicineTab(),
                _buildAdviceTab(),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _saveDraft,
                    child: const Text('Lưu nháp'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _completeAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E9F6E),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Hoàn tất'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: _isSaving ? null : _cancelAppointment,
                    child: const Text(
                      'Huỷ lịch',
                      style: TextStyle(color: Color(0xFFC62828)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        _sectionCard(
          title: 'Triệu chứng hiện tại',
          child: TextField(
            controller: _symptomsController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Nhập triệu chứng bệnh nhân mô tả...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosisTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        _sectionCard(
          title: 'Khám lâm sàng',
          child: TextField(
            controller: _examController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Nhập ghi chú khám lâm sàng...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Chẩn đoán',
          child: TextField(
            controller: _diagnosisController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Viêm họng cấp, tăng huyết áp độ 1...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        _sectionCard(
          title: 'Đơn thuốc',
          child: Column(
            children: [
              for (var i = 0; i < _medicines.length; i++)
                _medicineItem(
                  index: i,
                  data: _medicines[i],
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _medicines.add(_MedicineFormData.empty());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm thuốc'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        _sectionCard(
          title: 'Dặn dò sau khám',
          child: TextField(
            controller: _adviceController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Nhập hướng dẫn sử dụng thuốc, theo dõi, tái khám...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _medicineItem({required int index, required _MedicineFormData data}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6F7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Thuốc ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18345E),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _medicines.length <= 1
                    ? null
                    : () {
                        setState(() {
                          final item = _medicines.removeAt(index);
                          item.dispose();
                        });
                      },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          TextField(
            controller: data.nameController,
            decoration: const InputDecoration(
              labelText: 'Tên thuốc',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: data.doseController,
            decoration: const InputDecoration(
              labelText: 'Liều dùng',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: data.frequencyController,
            decoration: const InputDecoration(
              labelText: 'Số lần/ngày',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: data.durationController,
            decoration: const InputDecoration(
              labelText: 'Số ngày dùng',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: data.noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E8F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF112544),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _MedicineFormData {
  _MedicineFormData({
    required this.nameController,
    required this.doseController,
    required this.frequencyController,
    required this.durationController,
    required this.noteController,
  });

  factory _MedicineFormData.empty() {
    return _MedicineFormData(
      nameController: TextEditingController(),
      doseController: TextEditingController(),
      frequencyController: TextEditingController(),
      durationController: TextEditingController(),
      noteController: TextEditingController(),
    );
  }

  factory _MedicineFormData.fromMap(Map<String, dynamic> map) {
    return _MedicineFormData(
      nameController: TextEditingController(text: (map['name'] ?? '').toString()),
      doseController: TextEditingController(text: (map['dose'] ?? '').toString()),
      frequencyController: TextEditingController(
        text: (map['frequency'] ?? '').toString(),
      ),
      durationController: TextEditingController(
        text: (map['duration'] ?? '').toString(),
      ),
      noteController: TextEditingController(text: (map['note'] ?? '').toString()),
    );
  }

  final TextEditingController nameController;
  final TextEditingController doseController;
  final TextEditingController frequencyController;
  final TextEditingController durationController;
  final TextEditingController noteController;

  Map<String, String> toMap() {
    return {
      'name': nameController.text.trim(),
      'dose': doseController.text.trim(),
      'frequency': frequencyController.text.trim(),
      'duration': durationController.text.trim(),
      'note': noteController.text.trim(),
    };
  }

  void dispose() {
    nameController.dispose();
    doseController.dispose();
    frequencyController.dispose();
    durationController.dispose();
    noteController.dispose();
  }
}