import 'package:flutter/material.dart';
import 'doctor_prescription_builder_page.dart';

class DoctorAppointmentDetailPage extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> initialData;

  const DoctorAppointmentDetailPage({
    super.key,
    required this.appointmentId,
    required this.initialData,
  });

  @override
  State<DoctorAppointmentDetailPage> createState() => _DoctorAppointmentDetailPageState();
}

class _DoctorAppointmentDetailPageState extends State<DoctorAppointmentDetailPage> {
  int _currentStep = 0;
  final List<Map<String, dynamic>> _selectedServices = [];

  // Controllers
  late TextEditingController _symptomsController;
  late TextEditingController _physicalExamController;
  late TextEditingController _diagnosisController;
  late TextEditingController _treatmentController;
  late TextEditingController _notesController;

  final List<Map<String, dynamic>> _availableServices = [
    {'id': 'S001', 'name': 'Chụp CT Sọ não', 'category': 'Chẩn đoán hình ảnh', 'price': '1,200,000đ'},
    {'id': 'S002', 'name': 'Nội soi dạ dày', 'category': 'Thăm dò chức năng', 'price': '800,000đ'},
    {'id': 'S003', 'name': 'Siêu âm bụng tổng quát', 'category': 'Chẩn đoán hình ảnh', 'price': '250,000đ'},
    {'id': 'S005', 'name': 'Sinh hóa máu (Glucose, Urea)', 'category': 'Xét nghiệm', 'price': '150,000đ'},
    {'id': 'S006', 'name': 'Tổng phân tích tế bào máu', 'category': 'Xét nghiệm', 'price': '100,000đ'},
    {'id': 'S007', 'name': 'X-Quang ngực thẳng', 'category': 'Chẩn đoán hình ảnh', 'price': '120,000đ'},
  ];

  final List<Map<String, dynamic>> _icd10Results = [
    {'code': 'J02.9', 'name': 'Viêm họng cấp (Acute pharyngitis)'},
    {'code': 'I10', 'name': 'Tăng huyết áp vô căn (Primary hypertension)'},
    {'code': 'E11', 'name': 'Tiểu đường type 2 (Type 2 diabetes)'},
    {'code': 'K29.7', 'name': 'Viêm dạ dày (Gastritis)'},
    {'code': 'M54.5', 'name': 'Đau lưng thấp (Low back pain)'},
  ];

  @override
  void initState() {
    super.initState();
    _symptomsController = TextEditingController(text: widget.initialData['symptoms'] ?? '');
    _physicalExamController = TextEditingController();
    _diagnosisController = TextEditingController();
    _treatmentController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _physicalExamController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.initialData;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('Bàn làm việc Bác sĩ', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E47B5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildVitalsStrip(),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Color(0xFF0E47B5)),
              ),
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepTapped: (step) => setState(() => _currentStep = step),
                elevation: 0,
                controlsBuilder: _buildStepperControls,
                onStepContinue: () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    _saveAndPrescribe();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) setState(() => _currentStep--);
                },
                steps: [
                  _stepAnamnesis(data),
                  _stepPhysical(),
                  _stepServices(),
                  _stepConclusion(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsStrip() {
    return Container(
      color: const Color(0xFF0E47B5),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _vitalInfo('Mạch', '72', 'bpm'),
            _vDivider(),
            _vitalInfo('H.Áp', '120/80', 'mmHg'),
            _vDivider(),
            _vitalInfo('T.Độ', '36.8', '°C'),
          ],
        ),
      ),
    );
  }

  Widget _vitalInfo(String label, String val, String unit) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(width: 2),
            Text(unit, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 9)),
          ],
        ),
      ],
    );
  }

  Widget _vDivider() {
    return Container(width: 1, height: 20, color: Colors.white.withOpacity(0.1));
  }

  Widget _buildStepperControls(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: details.onStepCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                child: const Text('VỀ TRƯỚC', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A6680))),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: details.onStepContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E47B5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _currentStep == 3 ? 'KÊ ĐƠN & KẾT THÚC' : 'TIẾP THEO',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Step _stepAnamnesis(Map<String, dynamic> data) {
    return Step(
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      title: const Text('Bệnh sử', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientInfoCompact(data),
          const SizedBox(height: 24),
          _buildInputField('Triệu chứng / Chief Complaints', _symptomsController, Icons.medical_information_rounded, maxLines: 4),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFDEF7ED), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF0E9F6E)),
                SizedBox(width: 8),
                Expanded(child: Text('AI: Gợi ý phác đồ Viêm họng cấp (J02.9)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0E9F6E)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Step _stepPhysical() {
    return Step(
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      title: const Text('Khám', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField('Khám thực thể / Physical Exam', _physicalExamController, Icons.accessibility_new_rounded, maxLines: 6),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Tim đều', 'Phổi sạch', 'Họng đỏ'].map((tag) => ActionChip(
              label: Text(tag, style: const TextStyle(fontSize: 11)),
              onPressed: () => setState(() => _physicalExamController.text += "$tag, "),
              backgroundColor: Colors.white,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Step _stepServices() {
    return Step(
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      title: const Text('Dịch vụ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CHỈ ĐỊNH CẬN LÂM SÀNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC), letterSpacing: 1.0)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showServiceSelectionSheet,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('THÊM XÉT NGHIỆM / CĐHA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0E47B5),
              elevation: 0,
              side: const BorderSide(color: Color(0xFF0E47B5)),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_selectedServices.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedServices.map((s) => Chip(
                label: Text(s['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0E47B5))),
                backgroundColor: const Color(0xFFE1EFFE),
                onDeleted: () => setState(() => _selectedServices.remove(s)),
                deleteIconColor: const Color(0xFF0E47B5),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Step _stepConclusion() {
    return Step(
      isActive: _currentStep >= 3,
      state: _currentStep == 3 ? StepState.indexed : StepState.complete,
      title: const Text('Kết luận', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      content: Column(
        children: [
          _buildICD10Finder(),
          const SizedBox(height: 16),
          _buildInputField('Hướng điều trị', _treatmentController, Icons.lightbulb_rounded, maxLines: 3),
          const SizedBox(height: 16),
          _buildInputField('Ghi chú', _notesController, Icons.note_alt_rounded),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCompact(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundColor: const Color(0xFFE1EFFE), child: Text(data['patientName'][0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0E47B5)))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['patientName'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text('${data['age']} tuổi • ${data['gender']} • Nhóm: ${data['bloodType']}', style: const TextStyle(color: Color(0xFF5A6680), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5A6680))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF8A95AC), size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildICD10Finder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chẩn đoán (ICD-10) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5A6680))),
        const SizedBox(height: 8),
        TextFormField(
          controller: _diagnosisController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0E47B5), size: 18),
            hintText: 'Tìm mã bệnh...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _icd10Results.take(3).map((r) => ActionChip(
            label: Text(r['code']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            onPressed: () => setState(() => _diagnosisController.text = "[${r['code']}] ${r['name']}"),
            backgroundColor: Colors.white,
          )).toList(),
        ),
      ],
    );
  }

  void _showServiceSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('CHỈ ĐỊNH DỊCH VỤ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableServices.length,
                  itemBuilder: (context, i) {
                    final item = _availableServices[i];
                    final isSelected = _selectedServices.contains(item);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) {
                        setSheetState(() {
                          val! ? _selectedServices.add(item) : _selectedServices.remove(item);
                        });
                        setState(() {});
                      },
                      title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${item['category']} • ${item['price']}', style: const TextStyle(fontSize: 12)),
                      activeColor: const Color(0xFF0E47B5),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E47B5), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('XÁC NHẬN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAndPrescribe() {
    if (_diagnosisController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn chẩn đoán ICD-10'), backgroundColor: Colors.red));
      return;
    }
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => DoctorPrescriptionBuilderPage(
          patientData: widget.initialData,
          appointmentId: widget.appointmentId,
        )
      )
    );
  }
}