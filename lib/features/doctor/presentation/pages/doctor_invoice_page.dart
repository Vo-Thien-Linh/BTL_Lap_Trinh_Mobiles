import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';

class DoctorInvoicePage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedMeds;
  final double totalPrice;
  final Map<String, dynamic>? patientData;
  final String? appointmentId;

  const DoctorInvoicePage({
    super.key,
    required this.selectedMeds,
    required this.totalPrice,
    this.patientData,
    this.appointmentId,
  });

  @override
  State<DoctorInvoicePage> createState() => _DoctorInvoicePageState();
}

class _DoctorInvoicePageState extends State<DoctorInvoicePage> {
  bool _isConfirming = false;

  String _numberToWords(int number) {
    if (number == 0) return 'Không đồng';
    return '${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đồng';
  }

  Future<void> _handleFinalConfirm() async {
    setState(() => _isConfirming = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final patientId = widget.patientData?['patientId'] ?? widget.patientData?['id'] ?? 'unknown_patient';
      
      // 1. Save Invoice to Firestore
      final invoiceRef = await FirebaseFirestore.instance.collection('Invoices').add({
        'appointmentId': widget.appointmentId,
        'patientId': patientId,
        'doctorId': uid,
        'doctorName': widget.patientData?['doctorName'] ?? 'BS. VŨ TRƯỜNG PHI',
        'departmentName': widget.patientData?['departmentName'] ?? 'Nội Tổng Quát',
        'patientName': widget.patientData?['patientName'] ?? widget.patientData?['name'] ?? 'Khách hàng',
        'meds': widget.selectedMeds,
        'totalAmount': widget.totalPrice,
        'amount': widget.totalPrice,
        'discountAmount': 0.0,
        'serviceContent': widget.selectedMeds.isNotEmpty ? 'Thanh toán phí khám & thuốc' : 'Thanh toán phí khám bệnh',
        'expenseType': widget.selectedMeds.isNotEmpty ? 'Thuốc' : 'Tiền khám',
        'status': 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Appointment Status
      if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty) {
        await FirebaseFirestore.instance.collection('Appointments').doc(widget.appointmentId).update({
          'status': 'waiting_payment',
          'lastInvoiceId': invoiceRef.id,
          'diagnosis': widget.patientData?['diagnosis'] ?? 'Viêm họng cấp', // Placeholder diagnosis if missing
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Create Notification for Patient
      await FirebaseFirestore.instance.collection('Notifications').add({
        'title': '🔔 Yêu cầu thanh toán mới',
        'content': 'Bác sĩ đã hoàn tất khám. Vui lòng thanh toán hóa đơn trị giá ${_formatMoney(widget.totalPrice.toInt())}đ.',
        'type': 'payment',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'patientId': patientId, // Dạng chuẩn cho patientId
        'userId': patientId,    // Dự phòng cho userId
        'invoiceId': invoiceRef.id,
        'actionRoute': AppRoutes.paymentManagement, // Chuyển về danh sách hóa đơn để thanh toán
      });

      if (!mounted) return;

      // 4. Success Feedback
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi xử lý: $e'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFDEF7ED), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF0E9F6E), size: 64),
            ),
            const SizedBox(height: 24),
            const Text('Đã gửi thông báo!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'Đơn thuốc và hóa đơn đã được chuyển tới bệnh nhân để thanh toán.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF5A6680)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.doctorHome, (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E47B5),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('QUAY VỀ TRANG CHỦ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Phiếu Thu Tiền', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(onPressed: () => _handlePrint(), icon: const Icon(Icons.print_rounded)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHospitalHeader(),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Text('PHIẾU THU TIỀN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  Text('Mã BN: ${widget.patientData?['id'] ?? '701TSG.18030062'}', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildPatientInfo(),
            const SizedBox(height: 24),
            _buildBillingTable(),
            const SizedBox(height: 24),
            _buildPaymentSummary(),
            const SizedBox(height: 40),
            _buildSignatures(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: _isConfirming ? null : _handleFinalConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0E47B5),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: _isConfirming
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('XÁC NHẬN & GỬI YÊU CẦU THANH TOÁN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildHospitalHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.local_hospital_rounded, size: 50, color: Color(0xFF0E47B5)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BỆNH VIỆN TAI MŨI HỌNG SÀI GÒN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              Text('1-3 Trịnh Văn Cấn, P. Bến Thành, Q.1, TPHCM', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
              Text('SĐT: (028) 38.213.456', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfo() {
    final data = widget.patientData ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Khách hàng', data['patientName'] ?? data['name'] ?? 'ĐỖ THỊ PHÚC'),
        _infoRow('Thông tin', '${data['age'] ?? '56'} tuổi | ${data['gender'] ?? 'Nữ'}'),
        _infoRow('Địa chỉ', data['address'] ?? 'TP. Hồ Chí Minh'),
        _infoRow('Bác sĩ', 'BS. VŨ TRƯỜNG PHI'),
      ],
    );
  }

  Widget _infoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildBillingTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('II. Chi phí khám, chữa bệnh', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey[300]!, width: 0.5),
          columnWidths: const {
            0: FixedColumnWidth(30),
            1: FlexColumnWidth(4),
            2: FixedColumnWidth(35),
            4: FixedColumnWidth(60),
            5: FixedColumnWidth(70),
          },
          children: [
            _buildTableHeader(),
            _buildExamRow(),
            ...widget.selectedMeds.asMap().entries.map((e) => _buildMedRow(e.key + 2, e.value)),
          ],
        ),
      ],
    );
  }

  TableRow _buildTableHeader() {
    const style = TextStyle(fontSize: 9, fontWeight: FontWeight.w900);
    return const TableRow(
      decoration: BoxDecoration(color: Color(0xFFF8FAFD)),
      children: [
        Padding(padding: EdgeInsets.all(4), child: Text('TT', style: style, textAlign: TextAlign.center)),
        Padding(padding: EdgeInsets.all(4), child: Text('Mục', style: style)),
        Padding(padding: EdgeInsets.all(4), child: Text('SL', style: style, textAlign: TextAlign.center)),
        Padding(padding: EdgeInsets.all(4), child: Text('ĐVT', style: style, textAlign: TextAlign.center)),
        Padding(padding: EdgeInsets.all(4), child: Text('Đơn giá', style: style, textAlign: TextAlign.right)),
        Padding(padding: EdgeInsets.all(4), child: Text('Thành tiền', style: style, textAlign: TextAlign.right)),
      ],
    );
  }

  TableRow _buildExamRow() {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.w500);
    return const TableRow(
      children: [
        Padding(padding: EdgeInsets.all(6), child: Text('1', style: style, textAlign: TextAlign.center)),
        Padding(padding: EdgeInsets.all(6), child: Text('Phí khám bệnh chuyên khoa', style: style)),
        Padding(padding: EdgeInsets.all(6), child: Text('1', style: style, textAlign: TextAlign.center)),
        Padding(padding: EdgeInsets.all(6), child: Text('Lần', style: style, textAlign: TextAlign.center)),
        Padding(padding: EdgeInsets.all(6), child: Text('350.000', style: style, textAlign: TextAlign.right)),
        Padding(padding: EdgeInsets.all(6), child: Text('350.000', style: style, textAlign: TextAlign.right)),
      ],
    );
  }

  TableRow _buildMedRow(int index, Map<String, dynamic> med) {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.w500);
    final amount = (med['price'] ?? 0) * (med['quantity'] ?? 0);
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(6), child: Text('$index', style: style, textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(6), child: Text(med['name'], style: style)),
        Padding(padding: const EdgeInsets.all(6), child: Text('${med['quantity']}', style: style, textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(6), child: Text(med['unit'] ?? 'Viên', style: style, textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(6), child: Text(_formatMoney(med['price']), style: style, textAlign: TextAlign.right)),
        Padding(padding: const EdgeInsets.all(6), child: Text(_formatMoney(amount), style: style, textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Column(
      children: [
        _summaryRow('Tổng chi phí', _formatMoney(widget.totalPrice.toInt())),
        const Divider(),
        _summaryRow('Số tiền phải thanh toán', _formatMoney(widget.totalPrice.toInt()), isBold: true),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bằng chữ: ', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
            Expanded(child: Text(_numberToWords(widget.totalPrice.toInt()), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic))),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.w900 : FontWeight.w500)),
          Text(val, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSignatures() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          children: [
            Text('Người trả tiền', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            SizedBox(height: 40),
            Text('(Ký, họ tên)', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        Column(
          children: [
            Text('TP. Hồ Chí Minh, Ngày ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            const Text('Bác sĩ điều trị', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text('Phi', style: TextStyle(fontFamily: 'Cursive', fontSize: 24, color: Color(0xFF0E47B5))),
            const Text('BS. VŨ TRƯỜNG PHI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  String _formatMoney(dynamic val) {
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _handlePrint() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang chuẩn bị bản in...')));
  }
}
