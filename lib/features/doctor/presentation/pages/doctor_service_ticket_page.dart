import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorServiceTicketPage extends StatelessWidget {
  final Map<String, dynamic> patientData;
  final List<Map<String, dynamic>> services;

  const DoctorServiceTicketPage({
    super.key,
    required this.patientData,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> primaryService = services.isNotEmpty
        ? services.first
        : const <String, dynamic>{};
    final totalAmount = services.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['amount'] ?? item['price']),
    );
    final paidAmount = _toDouble(patientData['paidAmount']);
    final remainingAmount = (totalAmount - paidAmount).clamp(
      0,
      double.infinity,
    );
    final isPaid = remainingAmount <= 0 && totalAmount > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        title: const Text(
          'Phiếu Chỉ Định Dịch Vụ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF15233D),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Bệnh viện LPHV',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15233D),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'PHIẾU CHỈ ĐỊNH DỊCH VỤ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0E47B5),
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Mã phiếu: ${_text(['requestId', 'serviceRequestId', 'id'], fallback: 'N/A')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A95AC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: const Color(0xFFF8FAFD),
                    child: Column(
                      children: [
                        Text(
                          _serviceName(primaryService).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF15233D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          _text([
                            'roomNumber',
                            'roomName',
                          ], fallback: 'Chưa có phòng'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0E9F6E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'STT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8A95AC),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0E9F6E),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _text(['queueNumber'], fallback: '-'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0E9F6E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _infoGridRow(
                          'Họ tên:',
                          _text([
                            'patientName',
                            'fullName',
                            'name',
                          ], fallback: 'Bệnh nhân'),
                        ),
                        _infoGridRow(
                          'Mã người bệnh:',
                          _text([
                            'patientCode',
                            'patientId',
                            'userId',
                          ], fallback: 'N/A'),
                        ),
                        _infoGridRow(
                          'Ngày sinh:',
                          _text([
                            'dateOfBirth',
                            'dob',
                          ], fallback: 'Chưa cập nhật'),
                        ),
                        _infoGridRow(
                          'Ngày chỉ định:',
                          _formatDate(
                            patientData['createdAt'] ??
                                patientData['orderedAt'],
                          ),
                        ),
                        _infoGridRow(
                          'Tiền dịch vụ:',
                          '${_money(totalAmount)} đồng',
                          valueColor: const Color(0xFF0E9F6E),
                        ),
                        if (paidAmount > 0)
                          _infoGridRow(
                            'Đã thanh toán:',
                            '${_money(paidAmount)} đồng',
                            valueColor: const Color(0xFF0E9F6E),
                          ),
                        _infoGridRow(
                          'Còn phải trả:',
                          '${_money(remainingAmount)} đồng',
                          valueColor: isPaid
                              ? const Color(0xFF0E9F6E)
                              : const Color(0xFFD32F2F),
                        ),
                        _infoGridRow(
                          'Chẩn đoán:',
                          _text(['diagnosis'], fallback: 'Chưa có chẩn đoán'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoGridRow(
    String label,
    String value, {
    Color valueColor = const Color(0xFF15233D),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8A95AC),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã gửi yêu cầu in phiếu!')),
          );
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E9F6E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'XÁC NHẬN & IN PHIẾU',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  String _text(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = patientData[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _serviceName(Map<String, dynamic> service) {
    final value =
        service['serviceName'] ?? service['service'] ?? service['name'];
    return value?.toString() ?? 'Chưa chọn dịch vụ';
  }

  String _formatDate(dynamic value) {
    if (value is DateTime) return DateFormat('dd/MM/yyyy HH:mm').format(value);
    if (value is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(value.toDate());
    }
    return value?.toString() ??
        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
  }

  String _money(num value) => NumberFormat('#,###').format(value);

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(
          value?.toString().replaceAll('đ', '').replaceAll(',', '').trim() ??
              '',
        ) ??
        0.0;
  }
}
