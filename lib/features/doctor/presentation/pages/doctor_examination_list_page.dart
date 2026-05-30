import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_appointment_detail_page.dart';

class DoctorExaminationListPage extends StatefulWidget {
  const DoctorExaminationListPage({super.key});

  @override
  State<DoctorExaminationListPage> createState() => _DoctorExaminationListPageState();
}

class _DoctorExaminationListPageState extends State<DoctorExaminationListPage> {
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

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
      body: _currentUid == null 
        ? const Center(child: Text('Vui lòng đăng nhập'))
        : FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('Doctors').where('userId', isEqualTo: _currentUid).limit(1).get(),
            builder: (context, doctorSnap) {
              if (doctorSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              String actualDoctorId = _currentUid;
              if (doctorSnap.hasData && doctorSnap.data!.docs.isNotEmpty) {
                actualDoctorId = doctorSnap.data!.docs.first.id;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Appointments')
                    .where('doctorId', isEqualTo: actualDoctorId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allDocs = snapshot.data?.docs ?? [];
                  
                  // Filter cho những ca đang khám hoặc đang gọi
                  final inProgressDocs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status']?.toString() ?? '';
                    return status == 'calling' || status == 'ongoing';
                  }).toList();

                  // Sắp xếp tăng dần theo STT nếu có
                  inProgressDocs.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;
                    final sttA = dataA['queueNumber'] is num ? (dataA['queueNumber'] as num).toInt() : 999;
                    final sttB = dataB['queueNumber'] is num ? (dataB['queueNumber'] as num).toInt() : 999;
                    return sttA.compareTo(sttB);
                  });

                  return Column(
                    children: [
                      _buildSummaryHeader(inProgressDocs.length),
                      Expanded(
                        child: inProgressDocs.isEmpty 
                            ? const Center(child: Text('Không có bệnh nhân nào đang khám', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                itemCount: inProgressDocs.length,
                                itemBuilder: (context, index) {
                                  return _buildInProgressCard(inProgressDocs[index]);
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
    );
  }

  Widget _buildSummaryHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('$count', 'Đang thực hiện', const Color(0xFF0E47B5)),
          _summaryItem('0', 'Chờ kết quả', const Color(0xFFD97706)),
          _summaryItem('0', 'Đã có kết quả', const Color(0xFF0E9F6E)),
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

  Widget _buildInProgressCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final stt = data['queueNumber']?.toString() ?? '?';
    final patientName = data['patientName']?.toString() ?? 'Bệnh nhân';
    final status = data['status']?.toString() ?? '';
    
    String displayStatus = 'Đang khám';
    if (status == 'calling') displayStatus = 'Đang gọi...';

    // Parse dob to calculate age if possible
    String dobStr = data['patientDob']?.toString() ?? '';
    String age = '?';
    if (dobStr.isNotEmpty) {
      try {
        final parts = dobStr.split('/');
        if (parts.length == 3) {
          age = '${DateTime.now().year - int.parse(parts[2])}';
        }
      } catch (_) {}
    }
    final gender = data['patientGender']?.toString() ?? 'Chưa rõ';

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
                  child: Text(stt, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0E47B5))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF15233D))),
                      Text('$age tuổi • $gender', style: const TextStyle(fontSize: 12, color: Color(0xFF8A95AC), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                _statusBadge(displayStatus, const Color(0xFFE8F1FF), const Color(0xFF0E47B5)),
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
                _statusBadge('Chưa có', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
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
                        appointmentId: doc.id,
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
