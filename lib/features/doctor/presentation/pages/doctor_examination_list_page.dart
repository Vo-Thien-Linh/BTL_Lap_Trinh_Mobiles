import 'package:flutter/material.dart';
import 'doctor_appointment_detail_page.dart';

class DoctorExaminationListPage extends StatefulWidget {
  const DoctorExaminationListPage({super.key});

  @override
  State<DoctorExaminationListPage> createState() => _DoctorExaminationListPageState();
}

class _DoctorExaminationListPageState extends State<DoctorExaminationListPage> {
  final List<Map<String, dynamic>> _inProgressList = [
    {
      'stt': 1,
      'patientName': 'Bệnh nhân 1',
      'age': 28,
      'gender': 'Nữ',
      'doctor': 'BS. Trần Thị D1',
      'examStatus': 'Chờ dịch vụ',
      'serviceStatus': 'Chờ kết quả',
      'id': 'APPT-001',
      'bloodType': 'A',
      'dob': '04/02/1997',
      'insuranceId': 'HY100000009',
      'address': 'Hà Nội, Việt Nam',
    },
    {
      'stt': 2,
      'patientName': 'Lê Hoàng Nam',
      'age': 42,
      'gender': 'Nam',
      'doctor': 'BS. Trần Thị D1',
      'examStatus': 'Đang khám',
      'serviceStatus': 'Đã có kết quả',
      'id': 'APPT-005',
      'bloodType': 'O+',
      'dob': '15/08/1982',
      'insuranceId': 'BN888999111',
      'address': 'TP. Hồ Chí Minh',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        title: const Text('Bệnh nhân đang khám', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E47B5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang tải lại danh sách khám...'),
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
          _buildSummaryHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _inProgressList.length,
              itemBuilder: (context, index) {
                return _buildInProgressCard(_inProgressList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          _summaryItem('2', 'Đang thực hiện', const Color(0xFF0E47B5)),
          const Spacer(),
          _summaryItem('1', 'Chờ kết quả', const Color(0xFFD97706)),
          const Spacer(),
          _summaryItem('1', 'Đã có kết quả', const Color(0xFF0E9F6E)),
        ],
      ),
    );
  }

  Widget _summaryItem(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8A95AC))),
      ],
    );
  }

  Widget _buildInProgressCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFF3F6FC), borderRadius: BorderRadius.circular(12)),
                  child: Text('${data['stt']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0E47B5))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['patientName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF15233D))),
                      Text('${data['age']} tuổi • ${data['gender']}', style: const TextStyle(fontSize: 12, color: Color(0xFF8A95AC), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                _statusBadge(data['examStatus'], const Color(0xFFE8F1FF), const Color(0xFF0E47B5)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F4FA)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 16, color: Color(0xFF8A95AC)),
                const SizedBox(width: 8),
                const Text('Dịch vụ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5A6680))),
                const SizedBox(width: 8),
                _statusBadge(data['serviceStatus'], data['serviceStatus'] == 'Đã có kết quả' ? const Color(0xFFDEF7ED) : const Color(0xFFFEF3C7), data['serviceStatus'] == 'Đã có kết quả' ? const Color(0xFF0E9F6E) : const Color(0xFFD97706)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorAppointmentDetailPage(
                        appointmentId: data['id'],
                        initialData: data,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E47B5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('TIẾP TỤC KHÁM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: text)),
    );
  }
}
