import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'doctor_patient_detail_page.dart';

class DoctorPatientRecordsPage extends StatefulWidget {
  const DoctorPatientRecordsPage({super.key});

  @override
  State<DoctorPatientRecordsPage> createState() => _DoctorPatientRecordsPageState();
}

class _DoctorPatientRecordsPageState extends State<DoctorPatientRecordsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        title: const Text('Hồ sơ bệnh nhân', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: const Color(0xFF0E47B5),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang làm mới danh sách bệnh nhân...'),
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
          _buildSearchSection(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'patient')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data?.docs ?? [];
                
                // Filter client side for search
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['fullName'] ?? '').toString().toLowerCase();
                    final phone = (data['phone'] ?? '').toString();
                    return name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    // Convert Firestore data to match the expected format in UI components
                    final patient = {
                      'id': docs[index].id,
                      'name': data['fullName'] ?? data['username'] ?? 'Bệnh nhân',
                      'phone': data['phone'] ?? 'Chưa cập nhật',
                      'gender': data['gender'] ?? 'Chưa rõ',
                      'dob': data['dob'] ?? '--/--/----',
                      'age': _calculateAge(data['dob']),
                      'blood': data['bloodType'] ?? '?',
                      'insurance': data['insuranceNumber'] ?? 'Chưa có',
                    };
                    return _buildPatientCard(patient);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 0;
    try {
      final parts = dob.split('/');
      if (parts.length == 3) {
        final year = int.parse(parts[2]);
        return DateTime.now().year - year;
      }
    } catch (_) {}
    return 0;
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Tìm tên hoặc số điện thoại...',
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0E47B5)),
          filled: true,
          fillColor: const Color(0xFFF3F6FC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DoctorPatientDetailPage(patient: patient)),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFE8F1FF),
                  child: Text(
                    patient['name'][0].toUpperCase(),
                    style: const TextStyle(color: Color(0xFF0E47B5), fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
                      const SizedBox(height: 4),
                      Text(patient['phone'], style: const TextStyle(fontSize: 13, color: Color(0xFF8A95AC), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _infoChip(patient['gender'], const Color(0xFFE8F1FF), const Color(0xFF0E47B5)),
                          _infoChip('${patient['age']} tuổi', Colors.grey[100]!, Colors.grey[700]!),
                          _infoChip('Nhóm ${patient['blood']}', const Color(0xFFDEF7ED), const Color(0xFF0E9F6E)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: text)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text('Không tìm thấy bệnh nhân', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8A95AC))),
        ],
      ),
    );
  }
}
