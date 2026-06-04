import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../notification/presentation/utils/notification_facade.dart';

class DoctorServiceQueuePage extends StatefulWidget {
  const DoctorServiceQueuePage({super.key});

  @override
  State<DoctorServiceQueuePage> createState() => _DoctorServiceQueuePageState();
}

class _DoctorServiceQueuePageState extends State<DoctorServiceQueuePage> {
  String _activeFilter = 'Tất cả';
  final Set<String> _processingItems = <String>{};
  final List<String> _filters = [
    'Tất cả',
    'Xét nghiệm',
    'Siêu âm',
    'X-Quang',
    'CT Scan',
  ];

  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUid == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Doctors')
            .where('userId', isEqualTo: _currentUid)
            .limit(1)
            .get(),
        builder: (context, doctorSnap) {
          if (doctorSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          String actualDoctorId = _currentUid!;
          if (doctorSnap.hasData && doctorSnap.data!.docs.isNotEmpty) {
            actualDoctorId = doctorSnap.data!.docs.first.id;
          }

          final doctorIds = <String>{
            actualDoctorId,
            if (_currentUid != null) _currentUid!,
          }.where((id) => id.trim().isNotEmpty).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('LabOrders')
                .where('doctorId', whereIn: doctorIds)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = snapshot.data?.docs ?? [];
              final List<Map<String, dynamic>> serviceQueue = allDocs.map((
                doc,
              ) {
                final data = Map<String, dynamic>.from(
                  doc.data() as Map<String, dynamic>,
                );
                data['requestId'] = doc.id;
                data['serviceItems'] = _serviceItems(data);
                data['service'] = _serviceSummary(data);
                data['type'] = _serviceType(data);
                data['statusLabel'] = _statusLabel(data['status']);
                return data;
              }).toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(),
                  _buildSummaryStats(serviceQueue),
                  _buildCategoryFilters(),
                  _buildServiceList(serviceQueue),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: const Color(0xFF0D9488),
      title: const Text(
        'Hàng đợi dịch vụ',
        style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () => setState(() {}),
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
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

  Widget _buildSummaryStats(List<Map<String, dynamic>> queue) {
    final total = queue.length;
    final waiting = queue
        .where((q) => _statusKey(q['status']) == 'ordered')
        .length;
    final done = queue
        .where((q) => _statusKey(q['status']) == 'completed')
        .length;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('$total', 'Tổng số', const Color(0xFF15233D)),
            const VerticalDivider(),
            _statItem('$waiting', 'Đang chờ', const Color(0xFFD97706)),
            const VerticalDivider(),
            _statItem('$done', 'Đã xong', const Color(0xFF0E9F6E)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8A95AC),
          ),
        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D9488) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFFDDE6F7),
                  ),
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

  Widget _buildServiceList(List<Map<String, dynamic>> queue) {
    final filtered = _activeFilter == 'Tất cả'
        ? queue
        : queue.where((q) => _matchesFilter(q, _activeFilter)).toList();

    if (filtered.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'Không có dịch vụ nào',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

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
    final status =
        data['statusLabel']?.toString() ?? _statusLabel(data['status']);
    final type = data['type']?.toString() ?? '';
    final statusColor = _getStatusColor(status);
    final isPriority = data['priority'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getServiceIcon(type),
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  data['patientName']?.toString() ??
                                      'Bệnh nhân',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF15233D),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPriority)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'KHẨN',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            data['service']?.toString() ?? 'Dịch vụ',
                            style: TextStyle(
                              fontSize: 13,
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(status, statusColor),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF3F6FC)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: Color(0xFF8A95AC),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Chỉ định bởi: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A95AC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        data['orderedBy']?.toString() ?? 'Bác sĩ',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15233D),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      data['time']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5A6680),
                      ),
                    ),
                  ],
                ),
                if (data['notes'] != null &&
                    _statusKey(data['status']) != 'completed') ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF0F4FA)),
                    ),
                    child: Text(
                      'Ghi chú: ${data['notes']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5A6680),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_statusKey(data['status']) != 'completed')
            _buildActionButtons(data),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> data) {
    final status = _statusKey(data['status']);
    final isWaiting = status == 'ordered';
    final itemKey = _itemKey(data);
    final isProcessing = _processingItems.contains(itemKey);

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: isProcessing ? null : () => _handleServiceAction(data),
              style: ElevatedButton.styleFrom(
                backgroundColor: isWaiting
                    ? const Color(0xFF0D9488)
                    : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isWaiting ? 'THỰC HIỆN NGAY' : 'TRẢ KẾT QUẢ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          if (!isWaiting) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: isProcessing ? null : () {},
              icon: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFF0D9488),
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF3F6FC),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleServiceAction(Map<String, dynamic> data) async {
    final itemKey = _itemKey(data);
    if (_processingItems.contains(itemKey)) return;

    final isWaiting = _statusKey(data['status']) == 'ordered';
    final nextStatus = isWaiting ? 'in_progress' : 'completed';
    final nextStatusLabel = _statusLabel(nextStatus);

    setState(() {
      _processingItems.add(itemKey);
      data['status'] = nextStatus;
      data['statusLabel'] = nextStatusLabel;
    });

    try {
      final requestId = data['requestId']?.toString() ?? '';
      if (requestId.isEmpty) {
        throw StateError('Không xác định được phiếu dịch vụ để cập nhật.');
      }

      final now = FieldValue.serverTimestamp();
      final appointmentId = data['appointmentId']?.toString() ?? '';
      final batch = FirebaseFirestore.instance.batch();
      final orderRef = FirebaseFirestore.instance
          .collection('LabOrders')
          .doc(requestId);

      batch.set(orderRef, {
        'status': nextStatus,
        if (isWaiting) 'startedAt': now,
        if (!isWaiting) 'completedAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      if (appointmentId.isNotEmpty) {
        batch.set(
          FirebaseFirestore.instance
              .collection('Appointments')
              .doc(appointmentId),
          {
            'labOrderStatus': nextStatus,
            if (!isWaiting) 'labResultIds': FieldValue.arrayUnion([requestId]),
            'updatedAt': now,
          },
          SetOptions(merge: true),
        );
      }

      if (nextStatus == 'completed') {
        batch.set(
          FirebaseFirestore.instance.collection('LabResults').doc(requestId),
          {
            'labOrderId': requestId,
            'appointmentId': appointmentId,
            'medicalRecordId': data['medicalRecordId'],
            'patientId': data['patientId'],
            'doctorId': data['doctorId'],
            'resultItems': _serviceItems(
              data,
            ).map((item) => {...item, 'result': 'Đã hoàn tất'}).toList(),
            'conclusion': 'Đã hoàn tất dịch vụ/xét nghiệm.',
            'createdAt': now,
            'updatedAt': now,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (nextStatus == 'completed') {
        final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final patientId = data['patientId']?.toString() ?? '';
        final doctorId = (data['doctorId']?.toString().isNotEmpty == true)
            ? data['doctorId'].toString()
            : currentDoctorId;

        if (patientId.isEmpty || doctorId.isEmpty || appointmentId.isEmpty) {
          debugPrint(
            'Không gửi được thông báo trả kết quả vì thiếu patientId/doctorId/appointmentId.',
          );
        } else {
          await NotificationFacade.onServiceResultSubmitted(
            patientId: patientId,
            doctorId: doctorId,
            patientName: data['patientName']?.toString() ?? 'Bệnh nhân',
            serviceName: data['service']?.toString() ?? 'dịch vụ',
            appointmentId: appointmentId,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus == 'completed'
                ? 'Đã trả kết quả và gửi thông báo.'
                : 'Đã chuyển sang trạng thái đang thực hiện.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Notification error after service result: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật trạng thái nhưng gửi thông báo lỗi: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingItems.remove(itemKey));
      }
    }
  }

  String _itemKey(Map<String, dynamic> data) {
    final requestId = data['requestId']?.toString() ?? '';
    if (requestId.isNotEmpty) return requestId;
    final appointmentId = data['appointmentId']?.toString() ?? '';
    final service = data['service']?.toString() ?? '';
    return '$appointmentId-$service';
  }

  List<Map<String, dynamic>> _serviceItems(Map<String, dynamic> data) {
    final raw = data['testItems'] ?? data['serviceItems'] ?? data['services'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  String _serviceSummary(Map<String, dynamic> data) {
    final items = _serviceItems(data);
    if (items.isEmpty) {
      return data['service']?.toString() ??
          data['serviceName']?.toString() ??
          'Dịch vụ';
    }

    final names = items
        .map(
          (item) =>
              item['serviceName'] ??
              item['service'] ??
              item['name'] ??
              item['id'] ??
              'Dịch vụ',
        )
        .map((value) => value.toString())
        .toList();
    if (names.length <= 2) return names.join(', ');
    return '${names.take(2).join(', ')} +${names.length - 2}';
  }

  String _serviceType(Map<String, dynamic> data) {
    final explicitType = data['type']?.toString().trim();
    if (explicitType != null && explicitType.isNotEmpty) return explicitType;

    final items = _serviceItems(data);
    for (final item in items) {
      final category = (item['category'] ?? item['type'])?.toString().trim();
      if (category != null && category.isNotEmpty) return category;
    }
    return 'Xét nghiệm';
  }

  bool _matchesFilter(Map<String, dynamic> data, String filter) {
    final haystack = [
      data['type'],
      data['service'],
      ..._serviceItems(data).expand(
        (item) => [
          item['category'],
          item['type'],
          item['name'],
          item['serviceName'],
        ],
      ),
    ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');

    final normalizedFilter = filter.toLowerCase();
    if (haystack.contains(normalizedFilter)) return true;
    if (normalizedFilter.contains('x') && haystack.contains('x')) return true;
    if (normalizedFilter.contains('ct') && haystack.contains('ct')) return true;
    return false;
  }

  String _statusKey(dynamic status) {
    final value = status?.toString().trim().toLowerCase() ?? '';
    if (value == 'completed' ||
        value.contains('hoàn') ||
        value.contains('xong')) {
      return 'completed';
    }
    if (value == 'in_progress' ||
        value.contains('đang') ||
        value.contains('thực hiện')) {
      return 'in_progress';
    }
    return 'ordered';
  }

  String _statusLabel(dynamic status) {
    switch (_statusKey(status)) {
      case 'completed':
        return 'Hoàn tất';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'ordered':
      default:
        return 'Chờ thực hiện';
    }
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
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
