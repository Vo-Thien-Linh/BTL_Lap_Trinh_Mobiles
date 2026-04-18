import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../appointment/data/models/invoice_models.dart';
import '../../../../app/theme/app_colors.dart';

class DigitalReceiptPage extends StatelessWidget {
  final InvoiceModel invoice;
  const DigitalReceiptPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        title: const Text('BIÊN LAI ĐIỆN TỬ', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang chuẩn bị bản in/chia sẻ...'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildReceiptPaper(),
            const SizedBox(height: 32),
            _buildSafetyNote(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptPaper() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildSerratedEdge(),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    _buildHospitalHeader(),
                    const SizedBox(height: 40),
                    const Text('PHIẾU THU TIỀN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF15233D))),
                    Text('Số: ${invoice.id.toUpperCase()}', style: const TextStyle(fontSize: 11, color: Color(0xFF8A95AC), fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 40),
                    _buildInfoSection(),
                    const SizedBox(height: 32),
                    _buildBillingTable(),
                    const SizedBox(height: 32),
                    _buildPaymentSummary(),
                    const SizedBox(height: 60),
                    _buildSignatures(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 40,
            top: 140,
            child: _buildPaidStamp(),
          ),
        ],
      ),
    );
  }

  Widget _buildSerratedEdge() {
    return Row(
      children: List.generate(20, (index) => Expanded(
        child: Container(
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FA),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
      )),
    );
  }

  Widget _buildHospitalHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF0E47B5), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BỆNH VIỆN TAI MŨI HỌNG SÀI GÒN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF15233D))),
              Text('Phòng khám Quốc tế Premium', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0E47B5))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _infoRow('Khách hàng', 'Người bệnh hiện tại', isBold: true),
        _infoRow('Nội dung', invoice.serviceContent),
        _infoRow('Khoa khám', invoice.departmentName ?? 'Nội Tổng Quát'),
        _infoRow('Bác sĩ sĩ xử lý', invoice.doctorName ?? 'N/A'),
        _infoRow('Ngày thanh toán', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text('$label:', style: const TextStyle(fontSize: 12, color: Color(0xFF8A95AC), fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: const Color(0xFF15233D), fontWeight: isBold ? FontWeight.w900 : FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _buildBillingTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: const BoxDecoration(color: Color(0xFFF8FAFD), border: Border(top: BorderSide(color: Color(0xFFDDE6F7)), bottom: BorderSide(color: Color(0xFFDDE6F7)))),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('HÀNG MỤC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15233D)))),
              Expanded(child: Text('SL', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15233D)))),
              Expanded(flex: 2, child: Text('THÀNH TIỀN', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15233D)))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _tableRow('Phí khám chuyên khoa', '1', '350.000'),
        const SizedBox(height: 8),
        _tableRow('Dịch vụ đi kèm', '1', '0'),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFDDE6F7)),
      ],
    );
  }

  Widget _tableRow(String item, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5A6680)))),
          Expanded(child: Text(qty, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5A6680)))),
          Expanded(flex: 2, child: Text('$price đ', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF15233D)))),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TỔNG THANH TOÁN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
            Text('${NumberFormat('#,###').format(invoice.amount)} đ', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0E47B5))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Phương thức:', style: TextStyle(fontSize: 11, color: Color(0xFF8A95AC), fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE8F1FF), borderRadius: BorderRadius.circular(8)), child: const Text('Thanh toán trực tuyến', style: TextStyle(fontSize: 10, color: Color(0xFF0E47B5), fontWeight: FontWeight.w900))),
          ],
        ),
      ],
    );
  }

  Widget _buildPaidStamp() {
    return Transform.rotate(
      angle: -0.2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF0E9F6E), width: 4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text('ĐÃ THANH TOÁN', style: TextStyle(color: Color(0xFF0E9F6E), fontSize: 22, fontWeight: FontWeight.w900)),
            Text(DateFormat('dd/MM/yyyy').format(DateTime.now()), style: const TextStyle(color: Color(0xFF0E9F6E), fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatures() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          children: [
            Text('NGƯỜI NỘP TIỀN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
            SizedBox(height: 40),
            Text('Đã xác thực chữ ký số', style: TextStyle(fontSize: 9, color: Color(0xFF8A95AC), fontStyle: FontStyle.italic)),
          ],
        ),
        Column(
          children: [
            const Text('THỦ QUỸ BỆNH VIỆN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15233D))),
            const SizedBox(height: 40),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: NetworkImage('https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=VERIFIED_RECEIPT_701TSG'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDE6F7)),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Quét để tra cứu', style: TextStyle(fontSize: 8, color: Color(0xFF8A95AC), fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildSafetyNote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFDEF7ED), borderRadius: BorderRadius.circular(20)),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: Color(0xFF0E9F6E)),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Biên lai này có giá trị xác nhận thanh toán trực tuyến và được bảo mật bởi hệ thống y tế.',
              style: TextStyle(color: Color(0xFF03543F), fontSize: 11, fontWeight: FontWeight.bold, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
