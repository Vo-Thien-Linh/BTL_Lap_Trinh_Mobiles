import 'package:flutter/material.dart';

class DoctorServiceQueuePage extends StatefulWidget {
  const DoctorServiceQueuePage({super.key});

  @override
  State<DoctorServiceQueuePage> createState() => _DoctorServiceQueuePageState();
}

class _DoctorServiceQueuePageState extends State<DoctorServiceQueuePage> {
  String _activeFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Xét nghiệm', 'Siêu âm', 'X-Quang', 'CT Scan'];

  final List<Map<String, dynamic>> _serviceQueue = [
    {
      'patientName': 'Phạm Hải Đăng',
      'service': 'Xét nghiệm máu',
      'type': 'Xét nghiệm',
      'orderedBy': 'BS. Vũ Trường Phi',
      'time': '10:30',
      'status': 'Chờ thực hiện',
      'priority': 0,
      'notes': 'Kiểm tra đường huyết và mỡ máu.'
    },
    {
      'patientName': 'Nguyễn Thị Hoa',
      'service': 'Siêu âm tim',
      'type': 'Siêu âm',
      'orderedBy': 'BS. Trần Thị D1',
      'time': '11:15',
      'status': 'Đang thực hiện',
      'priority': 1,
      'notes': 'Nghi ngờ hở van 2 lá.'
    },
    {
      'patientName': 'Trần Văn Mạnh',
      'service': 'Chụp X-Quang phổi',
      'type': 'X-Quang',
      'orderedBy': 'BS. Lê Văn C',
      'time': '14:00',
      'status': 'Chờ thực hiện',
      'priority': 0,
      'notes': 'Theo dõi viêm phổi thùy.'
    },
    {
      'patientName': 'Lê Hoàng Nam',
      'service': 'Chụp CT Sọ não',
      'type': 'CT Scan',
      'orderedBy': 'BS. Vũ Trường Phi',
      'time': '14:30',
      'status': 'Hoàn tất',
      'priority': 1,
      'notes': 'Khẩn cấp - Chấn thương sọ não.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildSummaryStats(),
          _buildCategoryFilters(),
          _buildServiceList(),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: const Color(0xFF0D9488),
      title: const Text('Hàng đợi dịch vụ', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
      centerTitle: true,
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('4', 'Tổng số', const Color(0xFF15233D)),
            const VerticalDivider(),
            _statItem('2', 'Đang chờ', const Color(0xFFD97706)),
            const VerticalDivider(),
            _statItem('1', 'Đã xong', const Color(0xFF0E9F6E)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8A95AC))),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: _filters.map((f) {
            final isSelected = _activeFilter == f;
            return GestureDetector(
              onTap: () => setState(() => _activeFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D9488) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFDDE6F7)),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF5A6680),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildServiceList() {
    final filtered = _activeFilter == 'Tất cả'
        ? _serviceQueue
        : _serviceQueue.where((q) => q['type'] == _activeFilter).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildServiceCard(filtered[index]),
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> data) {
    final statusColor = _getStatusColor(data['status']);
    final isPriority = data['priority'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(_getServiceIcon(data['type']), color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(data['patientName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
                              if (isPriority)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('KHẨN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                                ),
                            ],
                          ),
                          Text(data['service'], style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    _statusBadge(data['status'], statusColor),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF3F6FC)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF8A95AC)),
                    const SizedBox(width: 6),
                    Text('Chỉ định bởi: ', style: TextStyle(fontSize: 12, color: const Color(0xFF8A95AC), fontWeight: FontWeight.w600)),
                    Text(data['orderedBy'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15233D))),
                    const Spacer(),
                    Text(data['time'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF5A6680))),
                  ],
                ),
                if (data['notes'] != null && data['status'] != 'Hoàn tất') ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFD), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF0F4FA))),
                    child: Text('Ghi chú: ${data['notes']}', style: const TextStyle(fontSize: 11, color: Color(0xFF5A6680), fontStyle: FontStyle.italic)),
                  ),
                ],
              ],
            ),
          ),
          if (data['status'] != 'Hoàn tất')
            _buildActionButtons(data),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> data) {
    final isWaiting = data['status'] == 'Chờ thực hiện';

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  data['status'] = isWaiting ? 'Đang thực hiện' : 'Hoàn tất';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isWaiting ? const Color(0xFF0D9488) : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(isWaiting ? 'THỰC HIỆN NGAY' : 'TRẢ KẾT QUẢ', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
            ),
          ),
          if (!isWaiting) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0D9488)),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF3F6FC),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đang thực hiện':
        return const Color(0xFF0D9488);
      case 'Hoàn tất':
        return const Color(0xFF0E9F6E);
      case 'Chờ thực hiện':
      default:
        return const Color(0xFFD97706);
    }
  }

  IconData _getServiceIcon(String type) {
    switch (type) {
      case 'Xét nghiệm':
        return Icons.biotech_rounded;
      case 'Siêu âm':
        return Icons.waves_rounded;
      case 'X-Quang':
      case 'CT Scan':
        return Icons.settings_accessibility_rounded;
      default:
        return Icons.science_rounded;
    }
  }
}
