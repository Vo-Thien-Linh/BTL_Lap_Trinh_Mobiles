import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorPatientDetailPage extends StatelessWidget {
  final Map<String, dynamic> patient;

  const DoctorPatientDetailPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        title: const Text('Chi tiết bệnh nhân', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: const Color(0xFF0E47B5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showMoreOptions(context), 
            icon: const Icon(Icons.more_vert_rounded)
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Appointments')
            .where('patientId', isEqualTo: patient['id'])
            .orderBy('appointmentDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final history = snapshot.data?.docs ?? [];
          Map<String, dynamic> latestVitals = patient['vitals'] ?? {};
          
          if (history.isNotEmpty) {
            final latest = history.first.data() as Map<String, dynamic>;
            if (latest['vitals'] != null) {
              latestVitals = latest['vitals'];
            }
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                _buildAllergyAlert(),
                _buildVitalsDashboard(latestVitals),
                _buildMedicalAssetsSection(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LỊCH SỬ KHÁM BỆNH', style: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC))),
                      const SizedBox(height: 20),
                      if (history.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Chưa có lịch sử khám', style: TextStyle(color: Color(0xFF8A95AC)))))
                      else
                        _buildMedicalHistoryTimeline(history),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0E47B5),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Text(patient['name'][0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0E47B5))),
            ),
          ),
          const SizedBox(height: 16),
          Text(patient['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _headerChip('Mã: ${patient['id'].toString().substring(0, min(8, patient['id'].toString().length))}'),
              const SizedBox(width: 8),
              _headerChip(patient['blood'] != null ? 'Nhóm: ${patient['blood']}' : 'Nhóm: ?'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _headerInfo('SĐT', patient['phone'] ?? 'N/A'),
                _verticalDivider(),
                _headerInfo('GIỚI TÍNH', patient['gender'] ?? 'N/A'),
                _verticalDivider(),
                _headerInfo('BHYT', (patient['insurance'] ?? 'N/A').toString().split('...')[0]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;

  Widget _headerChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _headerInfo(String label, String val) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 25, color: Colors.white.withOpacity(0.1));
  }

  Widget _buildAllergyAlert() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD1D1), width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFE02424)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DỊ ỨNG & CẢNH BÁO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFE02424))),
                Text('Dị ứng Penicillin, Phấn hoa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF9B1C1C))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsDashboard(Map<String, dynamic> vitals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('CHỈ SỐ SINH TỒN (LATEST)', style: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC))),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _vitalStat('Huyết áp', vitals['bloodPressure'] ?? '--/--', 'mmHg', Icons.monitor_heart_rounded, const Color(0xFF0E47B5)),
              _vitalStat('Nhịp tim', vitals['heartRate'] ?? '--', 'bpm', Icons.favorite_rounded, const Color(0xFFE02424)),
              _vitalStat('SpO2', vitals['spO2'] ?? '--', '%', Icons.bloodtype_rounded, const Color(0xFF0E9F6E)),
              _vitalStat('Nhiệt độ', vitals['temperature'] ?? '--', '°C', Icons.thermostat_rounded, const Color(0xFFD97706)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vitalStat(String label, String val, String unit, IconData icon, Color color) {
    return Container(
      width: 130,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: color),
              Text(unit, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8A95AC))),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8A95AC))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalAssetsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('HÌNH ẢNH & XÉT NGHIỆM', style: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC))),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _assetThumbnail(
                context, 
                'Xét nghiệm máu', 
                Icons.picture_as_pdf_rounded, 
                const Color(0xFFE02424),
                () => _showAssetViewer(context, 'Xét nghiệm máu', 'lab_result'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _assetThumbnail(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F4FA)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15233D))),
          ],
        ),
      ),
    );
  }

  void _showAssetViewer(BuildContext context, String title, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _buildLabResultReport(),
            ),
            _buildAssetActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabResultReport() {
    final tests = [
      {'name': 'WBC (Bạch cầu)', 'val': '7.2', 'unit': 'G/L', 'ref': '4.0 - 10.0', 'status': 'Bình thường'},
      {'name': 'RBC (Hồng cầu)', 'val': '4.8', 'unit': 'T/L', 'ref': '3.8 - 5.5', 'status': 'Bình thường'},
      {'name': 'HGB (Hemoglobin)', 'val': '110', 'unit': 'g/L', 'ref': '120 - 160', 'status': 'Thấp'},
      {'name': 'PLT (Tiểu cầu)', 'val': '250', 'unit': 'G/L', 'ref': '150 - 450', 'status': 'Bình thường'},
      {'name': 'Glucose', 'val': '5.4', 'unit': 'mmol/L', 'ref': '3.9 - 6.4', 'status': 'Bình thường'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('KẾT QUẢ XÉT NGHIỆM MÁU TỔNG QUÁT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0E47B5))),
          const Text('Ngày thực hiện: 12/04/2026', style: TextStyle(fontSize: 11, color: Color(0xFF8A95AC))),
          const SizedBox(height: 20),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                children: ['Chỉ số', 'Kết quả', 'Trạng thái'].map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(h, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF8A95AC))),
                )).toList(),
              ),
              ...tests.map((t) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Tham chiếu: ${t['ref']} ${t['unit']}', style: const TextStyle(fontSize: 10, color: Color(0xFF8A95AC))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(t['val']!, style: TextStyle(fontWeight: FontWeight.w900, color: t['status'] == 'Thấp' ? Colors.red : const Color(0xFF15233D))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _statusBadge(t['status']!),
                  ),
                ],
              )).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isLow = status == 'Thấp';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: isLow ? const Color(0xFFFFF5F5) : const Color(0xFFF3F6FC), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isLow ? Colors.red : const Color(0xFF5A6680))),
    );
  }

  Widget _buildAssetActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Tải về máy'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3F6FC), foregroundColor: const Color(0xFF15233D), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share_rounded),
              label: const Text('Chia sẻ'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E47B5), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryTimeline(List<QueryDocumentSnapshot> history) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final doc = history[index];
        final data = doc.data() as Map<String, dynamic>;
        final isLast = index == history.length - 1;
        
        final date = data['appointmentDate'] != null 
            ? DateFormat('dd/MM/yyyy').format((data['appointmentDate'] as Timestamp).toDate())
            : '---';

        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: Color(0xFF0E47B5), shape: BoxShape.circle),
                  ),
                  if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFD1D5DB))),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(date, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0E47B5))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFF3F6FC), borderRadius: BorderRadius.circular(6)),
                            child: Text(data['shiftId'] ?? 'Khám thường', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5A6680))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person_pin_rounded, size: 14, color: Color(0xFF8A95AC)),
                          const SizedBox(width: 6),
                          Text(data['doctorName'] ?? 'Bác sĩ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15233D))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('CHẨN ĐOÁN:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC))),
                      const SizedBox(height: 4),
                      Text(data['diagnosis'] ?? 'Chưa có chẩn đoán', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF15233D))),
                      if (data['notes'] != null) ...[
                        const SizedBox(height: 12),
                        const Text('DẶN DÒ:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC))),
                        const SizedBox(height: 4),
                        Text(data['notes'], style: const TextStyle(fontSize: 12, color: Color(0xFF5A6680))),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(36), topRight: Radius.circular(36)),
        ),
        child: Column(
          children: [
            Container(
              width: 50, height: 5, 
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIdentityCard(),
                    const SizedBox(height: 32),
                    _buildSectionLabel('CÔNG CỤ CHUYÊN MÔN'),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.edit_note_rounded,
                      title: 'Chỉnh sửa hồ sơ',
                      desc: 'Cập nhật tiền sử, dị ứng và thông tin cá nhân',
                      color: const Color(0xFF0E47B5),
                      onTap: () {
                        Navigator.pop(context);
                        _handleEditProfile(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.star_rounded,
                      title: 'Ưu tiên theo dõi',
                      desc: 'Ghim bệnh nhân vào danh sách giám sát đặc biệt',
                      color: const Color(0xFFD97706),
                      onTap: () {
                        Navigator.pop(context);
                        _handleWatchlist(context);
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildSectionLabel('HỒ SƠ & BÁO CÁO'),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.picture_as_pdf_rounded,
                      title: 'Xuất tóm tắt hồ sơ (PDF)',
                      desc: 'Tạo bản tổng hợp kết quả lâm sàng và đơn thuốc',
                      color: const Color(0xFFE02424),
                      onTap: () {
                        Navigator.pop(context);
                        _handleExportPDF(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.share_rounded,
                      title: 'Chia sẻ hội chẩn',
                      desc: 'Gửi mã truy cập an toàn cho bác sĩ đồng nghiệp',
                      color: const Color(0xFF0E9F6E),
                      onTap: () {
                        Navigator.pop(context);
                        _handleShareRecord(context);
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildSectionLabel('HỆ THỐNG'),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.history_rounded,
                      title: 'Nhật ký thay đổi',
                      desc: 'Xem lịch sử các lần cập nhật thông tin bệnh án',
                      color: const Color(0xFF64748B),
                      onTap: () {
                        Navigator.pop(context);
                        _handleActivityLog(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.archive_rounded,
                      title: 'Lưu trữ hồ sơ',
                      desc: 'Ngưng tiếp nhận tạm thời hoặc chuyển tuyến',
                      color: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(context);
                        _handleArchiveRecord(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0E47B5).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                ),
                child: Center(
                  child: Text(patient['name'][0], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient['name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('ID: ${patient['id'].toString().substring(0, min(8, patient['id'].toString().length))}...', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Icon(Icons.copy_rounded, color: Colors.white.withOpacity(0.3), size: 14),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.2), borderRadius: BorderRadius.circular(100), border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3))),
                child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _identityStat('NHÓM MÁU', patient['blood'] ?? '?', Icons.bloodtype_rounded, Colors.redAccent),
              _identityStat('TUỔI', '${patient['age'] ?? '??'} Tuổi', Icons.cake_rounded, Colors.orangeAccent),
              _identityStat('BHYT', 'HỢP LỆ', Icons.verified_user_rounded, Colors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _identityStat(String label, String val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.7), size: 16),
        const SizedBox(height: 8),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC), letterSpacing: 1.5));
  }

  Widget _buildActionCard({required IconData icon, required String title, required String desc, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  // --- HANDLER METHODS ---

  void _handleEditProfile(BuildContext context) {
    final nameController = TextEditingController(text: patient['name']);
    final phoneController = TextEditingController(text: patient['phone']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('CHỈNH SỬA HỒ SƠ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(patient['id']).update({
                  'fullName': nameController.text,
                  'phone': phoneController.text,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật hồ sơ thành công!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E47B5), foregroundColor: Colors.white),
            child: const Text('LƯU THAY ĐỔI'),
          ),
        ],
      ),
    );
  }

  void _handleWatchlist(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã ghim bệnh nhân ${patient['name']} vào danh sách ưu tiên theo dõi.'),
        backgroundColor: const Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleExportPDF(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFE02424)),
            const SizedBox(height: 24),
            const Text('Đang tạo báo cáo y tế...', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Hệ thống đang tổng hợp dữ liệu cho ${patient['name']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Báo cáo PDF đã được lưu vào thư mục Tải về.')));
      }
    });
  }

  void _handleShareRecord(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security_rounded, size: 48, color: Color(0xFF0E9F6E)),
            const SizedBox(height: 16),
            const Text('CHIA SẺ HỘI CHẨN AN TOÀN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 12),
            const Text('Cấp mã truy cập tạm thời cho bác sĩ khác để xem hồ sơ này trong 24 giờ.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF0E9F6E).withOpacity(0.2))),
              child: const Text('MED-ACCESS-99281', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF0E9F6E))),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E9F6E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('SAO CHÉP MÃ TRUY CẬP'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleActivityLog(BuildContext context) {
    final activities = [
      {'time': '10:30 Hôm nay', 'event': 'Bác sĩ cập nhật đơn thuốc mới', 'icon': Icons.medication_rounded, 'color': Colors.blue},
      {'time': '09:15 Hôm nay', 'event': 'Kết quả xét nghiệm máu đã được tải lên', 'icon': Icons.science_rounded, 'color': Colors.red},
      {'time': 'Hôm qua, 14:20', 'event': 'Khai báo tiền sử bệnh (Dị ứng phấn hoa)', 'icon': Icons.warning_amber_rounded, 'color': Colors.orange},
      {'time': '12/04/2026', 'event': 'Khởi tạo hồ sơ bệnh án điện tử', 'icon': Icons.create_new_folder_rounded, 'color': Colors.green},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NHẬT KÝ THAY ĐỔI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final act = activities[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: (act['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(act['icon'] as IconData, color: act['color'] as Color, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(act['event'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(act['time'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleArchiveRecord(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('XÁC NHẬN LƯU TRỮ', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
        content: const Text('Hồ sơ sẽ được chuyển vào mục lưu trữ. Bạn có chắc chắn muốn ngưng theo dõi bệnh nhân này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('LƯU TRỮ NGAY'),
          ),
        ],
      ),
    );
  }
}
