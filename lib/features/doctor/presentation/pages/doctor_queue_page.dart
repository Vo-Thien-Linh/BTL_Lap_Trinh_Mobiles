import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../appointment/data/models/appointment_models.dart';
import 'doctor_appointment_detail_page.dart';

class DoctorQueuePage extends StatefulWidget {
  const DoctorQueuePage({super.key});

  @override
  State<DoctorQueuePage> createState() => _DoctorQueuePageState();
}

class _DoctorQueuePageState extends State<DoctorQueuePage> {
  String _selectedFilter = 'Đang chờ';
  final List<String> _filters = ['Tất cả', 'Đang chờ', 'Đang gọi', 'Đang khám', 'Vắng mặt'];
  bool _isLoading = false;
  final String? _currentDoctorId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedFilter = 'Đang chờ';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật danh sách hàng đợi mới nhất'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showPatientBottomSheet(HospitalAppointmentModel data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPatientDetailSheet(data),
    );
  }

  Widget _buildPatientDetailSheet(HospitalAppointmentModel data) {
    final waitDuration = DateTime.now().difference(data.createdAt);
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thông tin ca khám', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
              _triageBadge(3),
            ],
          ),
          const SizedBox(height: 24),
          _detailInfoRow(Icons.person_rounded, 'Bệnh nhân', data.patientName),
          _detailInfoRow(Icons.calendar_month_rounded, 'Thời gian đặt', data.timeSlot),
          _detailInfoRow(Icons.timer_outlined, 'Đã chờ', '${waitDuration.inMinutes} phút'),
          const Divider(height: 32),
          const Text('TRIỆU CHỨNG LÂM SÀNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC), letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Text(data.symptoms, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF15233D))),
          const SizedBox(height: 32),
          
          if (data.status == 'pending') 
            _buildCallAction(data)
          else if (data.status == 'calling')
            _buildOngoingActions(data)
          else 
            _buildDefaultActions(data),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCallAction(HospitalAppointmentModel data) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _callPatient(data);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E47B5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.record_voice_over_rounded),
            SizedBox(width: 12),
            Text('GỌI BỆNH NHÂN NÀY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingActions(HospitalAppointmentModel data) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startExamination(data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E9F6E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('BẮT ĐẦU KHÁM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () {
            Navigator.pop(context);
            _markAsAbsent(data);
          },
          icon: const Icon(Icons.person_off_rounded, color: Color(0xFFE02424)),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFFFF5F5),
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: Color(0xFFFFD1D1)),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultActions(HospitalAppointmentModel data) {
    return Center(
      child: Text('Trạng thái: ${_formatStatus(data.status).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _detailInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF8A95AC)),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontSize: 14, color: Color(0xFF8A95AC))),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF15233D))),
        ],
      ),
    );
  }

  void _callPatient(HospitalAppointmentModel data) async {
    try {
      await FirebaseFirestore.instance.collection('Appointments').doc(data.id).update({
        'status': 'calling',
      });
      
      await FirebaseFirestore.instance.collection('Notifications').add({
        'userId': data.patientId,
        'title': 'Đến lượt khám của bạn',
        'message': 'Đã đến lượt khám của bạn (STT: ${data.queueNumber}). Mời bạn nhanh chóng di chuyển tới phòng khám để bác sĩ chuẩn bị.',
        'type': 'queue',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang gọi bệnh nhân và đã gửi thông báo')),
        );
      }
    } catch (e) {
      debugPrint('Error calling patient: $e');
    }
  }

  void _startExamination(HospitalAppointmentModel data) async {
    try {
      await FirebaseFirestore.instance.collection('Appointments').doc(data.id).update({
        'status': 'ongoing',
      });
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorAppointmentDetailPage(
              appointmentId: data.id,
              initialData: data.toFirestore(),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting exam: $e');
    }
  }

  void _markAsAbsent(HospitalAppointmentModel data) async {
    try {
      await FirebaseFirestore.instance.collection('Appointments').doc(data.id).update({
        'status': 'absent',
      });
      
      await FirebaseFirestore.instance.collection('Notifications').add({
        'userId': data.patientId,
        'title': 'Bỏ qua lượt khám',
        'message': 'Bác sĩ đã bỏ qua lượt của bạn do bạn vắng mặt tại phòng khám. Vui lòng liên hệ quầy tiếp đón.',
        'type': 'queue',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu vắng mặt và gửi thông báo')),
        );
      }
    } catch (e) {
      debugPrint('Error marking absent: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          _buildSmartCommandHub(),
          _buildFilterBar(),
          _buildQueueHeader(),
          _buildQueueListStream(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: const Color(0xFF0E47B5),
      elevation: 0,
      title: const Text('Hàng đợi điều hành', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white)),
      actions: [
        if (_isLoading)
          const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
        else
          IconButton(
            onPressed: _handleRefresh, 
            icon: const Icon(Icons.refresh_rounded, color: Colors.white)
          ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0E47B5), Color(0xFF1A56CE)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartCommandHub() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Appointments')
          .where('doctorId', isEqualTo: _currentDoctorId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final waitingCount = snapshot.data?.docs.length ?? 0;

        return SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: const Color(0xFF0E47B5).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _hubMetric('SẮP TỚI', '$waitingCount', const Color(0xFF0E47B5)),
                    _vDivider(),
                    _hubMetric('CÔNG SUẤT', '85%', const Color(0xFF0E9F6E)),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: waitingCount > 0 ? () {
                    final first = HospitalAppointmentModel.fromFirestore(snapshot.data!.docs.first);
                    _showPatientBottomSheet(first);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E47B5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    shadowColor: const Color(0xFF0E47B5).withOpacity(0.4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.record_voice_over_rounded),
                      SizedBox(width: 12),
                      Text('MỜI BỆNH NHÂN TIẾP THEO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _hubMetric(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC), letterSpacing: 0.5)),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 30, color: const Color(0xFFF3F6FC));

  Widget _buildFilterBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: _filters.map((f) {
              final isSelected = _selectedFilter == f;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF15233D) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (isSelected) 
                        BoxShadow(color: const Color(0xFF15233D).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                      if (!isSelected)
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.w900, 
                      color: isSelected ? Colors.white : const Color(0xFF5A6680),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(25, 0, 25, 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('DANH SÁCH HÀNG ĐỢI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC), letterSpacing: 1.5)),
            Icon(Icons.sort_rounded, size: 18, color: Color(0xFF8A95AC)),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueListStream() {
    if (_currentDoctorId == null) {
      return const SliverFillRemaining(child: Center(child: Text('Vui lòng đăng nhập')));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Appointments')
          .where('doctorId', isEqualTo: _currentDoctorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text('Lỗi: ${snapshot.error}')));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())));
        }

        final allDocs = snapshot.data?.docs ?? [];
        final List<HospitalAppointmentModel> allAppointments = allDocs.map((d) => HospitalAppointmentModel.fromFirestore(d)).toList();

        // Filtering
        List<HospitalAppointmentModel> filtered = allAppointments;
        if (_selectedFilter != 'Tất cả') {
          final mapping = {
            'Đang chờ': 'pending',
            'Đang gọi': 'calling',
            'Đang khám': 'ongoing',
            'Vắng mặt': 'absent'
          };
          filtered = allAppointments.where((a) => a.status == mapping[_selectedFilter]).toList();
        } else {
          filtered = allAppointments.where((a) => ['pending', 'calling', 'ongoing', 'absent'].contains(a.status)).toList();
        }

        filtered.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));

        if (filtered.isEmpty) {
          return const SliverFillRemaining(child: Center(child: Text('Hàng đợi trống', style: TextStyle(color: Colors.grey))));
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildPatientCard(filtered[index]),
              childCount: filtered.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatientCard(HospitalAppointmentModel data) {
    final waitDuration = DateTime.now().difference(data.createdAt);
    final triageColor = data.status == 'calling' ? const Color(0xFF0E47B5) : const Color(0xFF0E9F6E);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPatientBottomSheet(data),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: triageColor.withOpacity(0.1),
                      child: Text(
                        data.patientName.isNotEmpty ? data.patientName[0] : 'B', 
                        style: TextStyle(fontWeight: FontWeight.w900, color: triageColor, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data.patientName, 
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF15233D)),
                              ),
                              Text(
                                '${waitDuration.inMinutes}p trước', 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF8A95AC)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Giới tính: ${data.patientGender ?? "-"} • STT: ${data.queueNumber}', 
                            style: const TextStyle(fontSize: 12, color: Color(0xFF8A95AC), fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _triageBadge(3, compact: true),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFF3F6FC), borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  _formatStatus(data.status), 
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0E47B5)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFD), borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    'Lý do: ${data.symptoms}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF5A6680), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatStatus(String s) {
    if (s == 'pending') return 'Đang chờ';
    if (s == 'calling') return 'Đang gọi';
    if (s == 'ongoing') return 'Đang khám';
    if (s == 'absent') return 'Vắng mặt';
    return s.toUpperCase();
  }

  Color _getTriageColor(int level) {
    if (level == 1) return const Color(0xFFE02424);
    if (level == 2) return const Color(0xFFD97706);
    return const Color(0xFF0E9F6E);
  }

  Widget _triageBadge(int level, {bool compact = false}) {
    final color = _getTriageColor(level);
    final label = level == 1 ? 'KHẨN' : (level == 2 ? 'ƯU TIÊN' : 'THƯỜNG');
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: compact ? 9 : 11, fontWeight: FontWeight.w900, color: color)),
    );
  }
}
