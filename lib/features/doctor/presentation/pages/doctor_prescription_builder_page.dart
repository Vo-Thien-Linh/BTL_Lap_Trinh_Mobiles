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
  State<DoctorPrescriptionBuilderPage> createState() => _DoctorPrescriptionBuilderPageState();
}

class _DoctorPrescriptionBuilderPageState extends State<DoctorPrescriptionBuilderPage> {
  final List<Map<String, dynamic>> _templates = [
    {'title': 'Sốt xuất huyết', 'desc': 'Kê đơn tiêu chuẩn', 'medsCount': 3, 'color': Colors.redAccent},
    {'title': 'Viêm họng cấp', 'desc': 'Kháng sinh + Giảm đau', 'medsCount': 4, 'color': Colors.blueAccent},
    {'title': 'Đau dạ dày', 'desc': 'Bảo vệ niêm mạc', 'medsCount': 2, 'color': const Color(0xFF10B981)},
  ];

  final List<Map<String, dynamic>> _drugCatalog = [
    {'name': 'Amoxicillin', 'unit': 'Viên', 'strength': '500mg', 'category': 'Kháng sinh', 'price': 1500},
    {'name': 'Paracetamol', 'unit': 'Viên', 'strength': '500mg', 'category': 'Giảm đau', 'price': 500},
    {'name': 'Ibuprofen', 'unit': 'Viên', 'strength': '400mg', 'category': 'Kháng viêm', 'price': 1200},
    {'name': 'Omeprazole', 'unit': 'Viên', 'strength': '20mg', 'category': 'Dạ dày', 'price': 2500},
    {'name': 'Amlodipine', 'unit': 'Viên', 'strength': '5mg', 'category': 'Huyết áp', 'price': 3000},
    {'name': 'Metformin', 'unit': 'Viên', 'strength': '850mg', 'category': 'Tiểu đường', 'price': 2000},
  ];

  final List<Map<String, dynamic>> _selectedMeds = [];
  String _activeCategory = 'Tất cả';

  double get _totalPrice {
    double total = 350000; // Starting with Exam fee as in the sample image
    for (var med in _selectedMeds) {
      total += (med['quantity'] ?? 0) * (med['price'] ?? 0);
    }
    return total;
  }

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

  void _applyTemplate(Map<String, dynamic> template) {
    // Mock: Adding 3 predefined meds
    setState(() {
      _selectedMeds.addAll([
        {
          'name': 'Paracetamol', 'strength': '500mg', 'unit': 'Viên',
          'quantity': 10, 'morning': 1, 'noon': 1, 'evening': 1, 'timing': 'Sau ăn', 'duration': 3
        },
        {
          'name': 'Amoxicillin', 'strength': '500mg', 'unit': 'Viên',
          'quantity': 14, 'morning': 1, 'noon': 0, 'evening': 1, 'timing': 'Sau ăn', 'duration': 7
        },
      ]);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã áp dụng phác đồ ${template['title']}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        title: const Text('Kê đơn thuốc', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: const Color(0xFF7C3AED), // Distinctive Purple for Prescriptions
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTopSearch(),
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
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm nhanh tên thuốc...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 24, bottom: 16),
          child: Text('PHÁC ĐỒ MẪU', style: TextStyle(fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC))),
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
                    gradient: LinearGradient(colors: [(t['color'] as Color), (t['color'] as Color).withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                      Text('${t['medsCount']} loại thuốc', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11)),
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
    final categories = ['Tất cả', 'Kháng sinh', 'Giảm đau', 'Kháng viêm', 'Dạ dày'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 24, bottom: 16),
          child: Text('DANH MỤC THUỐC', style: TextStyle(fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC))),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFDDE6F7)),
                  ),
                  child: Text(c, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF5A6680), fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _drugCatalog.length,
          itemBuilder: (context, index) {
            final med = _drugCatalog[index];
            if (_activeCategory != 'Tất cả' && med['category'] != _activeCategory) return const SizedBox.shrink();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(med['name'], style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF15233D))),
              subtitle: Text('${med['strength']} | ${med['category']} | ${med['price']}đ/${med['unit']}', style: const TextStyle(fontSize: 12, color: Color(0xFF8A95AC))),
              trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF7C3AED)),
              onTap: () => _showAddMedicineModal(med),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrescriptionSummary() {
    if (_selectedMeds.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 32, bottom: 16),
          child: Text('ĐƠN THUỐC ĐÃ KÊ', style: TextStyle(fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC))),
        ),
        ..._selectedMeds.asMap().entries.map((entry) {
          final med = entry.value;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
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
                                Text(med['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF15233D))),
                                IconButton(onPressed: () => setState(() => _selectedMeds.removeAt(entry.key)), icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFD1D5DB))),
                              ],
                            ),
                            Text('${med['strength']} | ${med['price']}đ x ${med['quantity']} = ${((med['price'] ?? 0) * (med['quantity'] ?? 0))}đ', style: const TextStyle(fontSize: 13, color: Color(0xFF5A6680), fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _dosageItem('S', med['morning']),
                                _dosageItem('T', med['noon']),
                                _dosageItem('C', med['evening']),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFF3F6FC), borderRadius: BorderRadius.circular(8)),
                                  child: Text(med['timing'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED))),
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
      decoration: BoxDecoration(color: val > 0 ? const Color(0xFFE8F1FF) : const Color(0xFFF3F6FC), borderRadius: BorderRadius.circular(6)),
      child: Text('$label: $val', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: val > 0 ? const Color(0xFF1457CC) : Colors.grey)),
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
                Text('TỔNG THANH TOÁN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC))),
                Text('${_totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ', 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF7C3AED))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorInvoicePage(
                    selectedMeds: _selectedMeds,
                    totalPrice: _totalPrice,
                    patientData: widget.patientData,
                    appointmentId: widget.appointmentId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('XÁC NHẬN ĐƠN', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _DosingConfigModal extends StatefulWidget {
  final Map<String, dynamic> medicine;
  final Function(Map<String, dynamic>) onConfirm;

  const _DosingConfigModal({required this.medicine, required this.onConfirm});

  @override
  State<_DosingConfigModal> createState() => _DosingConfigModalState();
}

class _DosingConfigModalState extends State<_DosingConfigModal> {
  int _morning = 1, _noon = 0, _evening = 1, _duration = 7;
  int? _manualQty;
  String _timing = 'Sau ăn';

  @override
  Widget build(BuildContext context) {
    int total = _manualQty ?? (_morning + _noon + _evening) * _duration;

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 40),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(widget.medicine['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
          Text('${widget.medicine['strength']} | ${widget.medicine['category']}', style: const TextStyle(color: Color(0xFF8A95AC), fontSize: 13)),
          const SizedBox(height: 30),
          const Text('LIỀU DÙNG (VIÊN)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC), letterSpacing: 1.2)),
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
          const Text('THỜI ĐIỂM UỐNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC), letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: ['Trước ăn', 'Sau ăn', 'Khi đói', 'Trước đi ngủ'].map((t) {
              final isSelected = _timing == t;
              return GestureDetector(
                onTap: () => setState(() => _timing = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF3F6FC), borderRadius: BorderRadius.circular(12)),
                  child: Text(t, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF5A6680), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Số lượng tổng:', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF15233D))),
              SizedBox(
                width: 100,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF7C3AED)),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    Text('Thành tiền: ${(total * (widget.medicine['price'] ?? 0)).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ', 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
                    const Text('Đã bao gồm thuế GTGT', style: TextStyle(fontSize: 10, color: Color(0xFF0E9F6E), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
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
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('THÊM', style: TextStyle(fontWeight: FontWeight.w900)),
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
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5A6680))),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () => onChanged(val > 0 ? val - 1 : 0),
              child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFF3F6FC), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove, size: 16)),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('$val', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
            GestureDetector(
              onTap: () => onChanged(val + 1),
              child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFF3F6FC), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add, size: 16)),
            ),
          ],
        ),
      ],
    );
  }
}
