import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../payment/data/services/billing_calculation_service.dart';
import '../../data/doctor_clinical_firestore_service.dart';

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
  final DoctorClinicalFirestoreService _clinicalService =
      DoctorClinicalFirestoreService();
  bool _isConfirming = false;
  String? _draftPrescriptionId;
  Map<String, dynamic> _appointmentData = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
    _savePrescriptionDraft();
  }

  Future<void> _savePrescriptionDraft() async {
    if (widget.appointmentId == null ||
        widget.appointmentId!.isEmpty ||
        widget.selectedMeds.isEmpty) {
      return;
    }

    try {
      final prescriptionId = await _clinicalService.savePrescription(
        appointmentId: widget.appointmentId!,
        patientData: _effectivePatientData,
        medicines: widget.selectedMeds,
        medicalRecordId: _effectivePatientData['medicalRecordId']?.toString(),
        notes: _effectivePatientData['notes']?.toString() ?? '',
      );
      if (!mounted) return;
      setState(() => _draftPrescriptionId = prescriptionId);
    } catch (e) {
      debugPrint('Không lưu được bản nháp toa thuốc: $e');
    }
  }

  Future<void> _loadAppointmentData() async {
    if (widget.appointmentId == null || widget.appointmentId!.isEmpty) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('Appointments')
        .doc(widget.appointmentId)
        .get();
    if (!mounted) return;
    setState(() {
      _appointmentData = snapshot.data() ?? const <String, dynamic>{};
    });
  }

  Map<String, dynamic> get _effectivePatientData => <String, dynamic>{
    ..._appointmentData,
    ...(widget.patientData ?? const <String, dynamic>{}),
  };

  double get _examFee {
    final data = _effectivePatientData;
    final fee = data['consultationFee'] ?? data['examFee'] ?? 350000;
    if (fee is num) return fee.toDouble();
    return double.tryParse(fee.toString()) ?? 350000;
  }

  double get _medicineTotal {
    var total = 0.0;
    for (final med in widget.selectedMeds) {
      final price = _toMoneyValue(med['price']);
      final quantity = _toQuantity(med['quantity']);
      total += price * quantity;
    }
    return total;
  }

  List<Map<String, dynamic>> get _selectedServices {
    final raw =
        _effectivePatientData['services'] ??
        _effectivePatientData['serviceItems'] ??
        _effectivePatientData['testItems'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  double get _serviceTotal {
    var total = 0.0;
    for (final service in _selectedServices) {
      total += _toMoneyValue(
        service['amount'] ?? service['price'] ?? service['fee'],
      );
    }
    return total;
  }

  double get _effectiveTotalPrice => _examFee + _medicineTotal + _serviceTotal;

  String _dataText(List<String> keys, {String fallback = ''}) {
    final data = _effectivePatientData;
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String get _doctorSignatureLabel {
    final doctorName = _dataText(['doctorName'], fallback: 'Bác sĩ').trim();
    final parts = doctorName.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.last : doctorName;
  }

  String _invoiceContentText() {
    final parts = <String>['phí khám'];
    if (_selectedServices.isNotEmpty) parts.add('dịch vụ');
    if (widget.selectedMeds.isNotEmpty) parts.add('thuốc');
    return 'Thanh toán ${parts.join(' & ')}';
  }

  String _invoiceExpenseType() {
    if (_selectedServices.isNotEmpty && widget.selectedMeds.isNotEmpty) {
      return 'Dịch vụ & thuốc';
    }
    if (_selectedServices.isNotEmpty) return 'Dịch vụ';
    if (widget.selectedMeds.isNotEmpty) return 'Thuốc';
    return 'Tiền khám';
  }

  double _toMoneyValue(dynamic value) {
    if (value is num) return value.toDouble();
    final normalized =
        value
            ?.toString()
            .replaceAll('đ', '')
            .replaceAll('Ä‘', '')
            .replaceAll(',', '')
            .replaceAll('.', '')
            .trim() ??
        '';
    return double.tryParse(normalized) ?? 0.0;
  }

  double _toQuantity(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _numberToWords(int number) {
    if (number == 0) return 'Không đồng';
    return '${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đồng';
  }

  Future<void> _handleFinalConfirm() async {
    setState(() => _isConfirming = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final appointmentData =
          widget.appointmentId != null && widget.appointmentId!.isNotEmpty
          ? ((await FirebaseFirestore.instance
                        .collection('Appointments')
                        .doc(widget.appointmentId)
                        .get())
                    .data() ??
                const <String, dynamic>{})
          : const <String, dynamic>{};
      final effectivePatientData = <String, dynamic>{
        ...appointmentData,
        ...(widget.patientData ?? const <String, dynamic>{}),
      };
      final patientId =
          (effectivePatientData['patientId'] ??
                  effectivePatientData['userId'] ??
                  effectivePatientData['uid'] ??
                  effectivePatientData['id'] ??
                  '')
              .toString()
              .trim();
      if (patientId.isEmpty) {
        throw Exception('Không xác định được bệnh nhân để lưu đơn thuốc.');
      }
      String? prescriptionId = _draftPrescriptionId;

      if (widget.appointmentId != null &&
          widget.appointmentId!.isNotEmpty &&
          widget.selectedMeds.isNotEmpty &&
          prescriptionId == null) {
        prescriptionId = await _clinicalService.savePrescription(
          appointmentId: widget.appointmentId!,
          patientData: effectivePatientData,
          medicines: widget.selectedMeds,
          notes: effectivePatientData['notes']?.toString() ?? '',
        );
      }

      final billing = await BillingCalculationService(
        firestore: FirebaseFirestore.instance,
      ).calculate(patientId: patientId, originalAmount: _effectiveTotalPrice);

      final invoiceData = {
        'appointmentId': widget.appointmentId,
        'patientId': patientId,
        'doctorId': uid,
        'doctorName': effectivePatientData['doctorName'] ?? 'Bác sĩ',
        'departmentName': effectivePatientData['departmentName'] ?? '',
        'patientName':
            effectivePatientData['patientName'] ??
            effectivePatientData['fullName'] ??
            effectivePatientData['name'] ??
            'Bệnh nhân',
        'meds': widget.selectedMeds,
        'serviceItems': _selectedServices,
        'examFee': _examFee,
        'serviceTotal': _serviceTotal,
        'medicineTotal': _medicineTotal,
        ...billing.toFirestoreFields(),
        'serviceContent': _invoiceContentText(),
        '_legacyServiceContentUnused': widget.selectedMeds.isNotEmpty
            ? 'Thanh toán phí khám & thuốc'
            : 'Thanh toán phí khám bệnh',
        'expenseType': widget.selectedMeds.isNotEmpty ? 'Thuốc' : 'Tiền khám',
        'status': 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      invoiceData
        ..remove('_legacyServiceContentUnused')
        ..['expenseType'] = _invoiceExpenseType();
      if (prescriptionId != null) {
        invoiceData['prescriptionId'] = prescriptionId;
      }

      final invoiceRef = await FirebaseFirestore.instance
          .collection('Invoices')
          .add(invoiceData);

      if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty) {
        final appointmentUpdate = {
          'patientId': patientId,
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'paymentStatus': 'unpaid',
          'lastInvoiceId': invoiceRef.id,
          'lastInvoiceAmount': billing.finalAmount,
          'invoiceAmount': billing.finalAmount,
          'invoiceOriginalAmount': _effectiveTotalPrice,
          'discountAmount': billing.discountAmount,
          'examFee': _examFee,
          'serviceTotal': _serviceTotal,
          'medicineTotal': _medicineTotal,
          'serviceItems': _selectedServices,
          'services': _selectedServices,
          'prescription': widget.selectedMeds,
          'diagnosis': effectivePatientData['diagnosis'] ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (prescriptionId != null) {
          appointmentUpdate['prescriptionId'] = prescriptionId;
        }

        await FirebaseFirestore.instance
            .collection('Appointments')
            .doc(widget.appointmentId)
            .set(appointmentUpdate, SetOptions(merge: true));
      }

      await FirebaseFirestore.instance.collection('Notifications').add({
        'title': 'Yêu cầu thanh toán mới',
        'content':
            'Bác sĩ đã hoàn tất khám. Vui lòng thanh toán hóa đơn trị giá ${_formatMoney(billing.finalAmount.toInt())}đ.',
        'type': 'payment',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'patientId': patientId,
        'userId': patientId,
        'invoiceId': invoiceRef.id,
        'actionRoute': AppRoutes.paymentManagement,
      });

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xử lý: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
              decoration: BoxDecoration(
                color: const Color(0xFFDEF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF0E9F6E),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đã gửi thông báo!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
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
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.doctorHome,
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E47B5),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'QUAY VỀ TRANG CHỦ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
        title: const Text(
          'Phiếu Thu Tiền',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () => _handlePrint(),
            icon: const Icon(Icons.print_rounded),
          ),
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
                  const Text(
                    'PHIẾU THU TIỀN',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Mã BN: ${_dataText(['patientCode', 'patientId', 'userId', 'uid', 'id'], fallback: 'N/A')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isConfirming ? null : _handleFinalConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0E47B5),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: _isConfirming
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'XÁC NHẬN & GỬI YÊU CẦU THANH TOÁN',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
        ),
      ),
    );
  }

  Widget _buildHospitalHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.local_hospital_rounded,
          size: 50,
          color: Color(0xFF0E47B5),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BỆNH VIỆN TAI MŨI HỌNG SÀI GÒN',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              Text(
                '1-3 Trịnh Văn Cấn, P. Bến Thành, Q.1, TPHCM',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
              Text(
                'SĐT: (028) 38.213.456',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfo() {
    final data = _effectivePatientData;
    final ageOrDob = data['age'] != null
        ? '${data['age']} tuổi'
        : _dataText(['dateOfBirth', 'dob'], fallback: 'Chưa có ngày sinh');
    final gender = _dataText(['gender'], fallback: 'Chưa có giới tính');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(
          'Khách hàng',
          _dataText(['patientName', 'fullName', 'name'], fallback: 'Bệnh nhân'),
        ),
        _infoRow('Thông tin', '$ageOrDob | $gender'),
        _infoRow('Địa chỉ', _dataText(['address'], fallback: 'Chưa cập nhật')),
        _infoRow('Bác sĩ', _dataText(['doctorName'], fallback: 'Bác sĩ')),
        if (_dataText(['departmentName']).isNotEmpty)
          _infoRow('Khoa', _dataText(['departmentName'])),
      ],
    );
  }

  Widget _infoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            val,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'II. Chi phí khám, chữa bệnh',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
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
            ..._selectedServices.asMap().entries.map(
              (e) => _buildServiceRow(e.key + 2, e.value),
            ),
            ...widget.selectedMeds.asMap().entries.map(
              (e) =>
                  _buildMedRow(e.key + _selectedServices.length + 2, e.value),
            ),
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
        Padding(
          padding: EdgeInsets.all(4),
          child: Text('TT', style: style, textAlign: TextAlign.center),
        ),
        Padding(
          padding: EdgeInsets.all(4),
          child: Text('Mục', style: style),
        ),
        Padding(
          padding: EdgeInsets.all(4),
          child: Text('SL', style: style, textAlign: TextAlign.center),
        ),
        Padding(
          padding: EdgeInsets.all(4),
          child: Text('ĐVT', style: style, textAlign: TextAlign.center),
        ),
        Padding(
          padding: EdgeInsets.all(4),
          child: Text('Đơn giá', style: style, textAlign: TextAlign.right),
        ),
        Padding(
          padding: EdgeInsets.all(4),
          child: Text('Thành tiền', style: style, textAlign: TextAlign.right),
        ),
      ],
    );
  }

  TableRow _buildExamRow() {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.w500);
    final formattedFee = _formatMoney(_examFee.toInt());
    return TableRow(
      children: [
        const Padding(
          padding: EdgeInsets.all(6),
          child: Text('1', style: style, textAlign: TextAlign.center),
        ),
        const Padding(
          padding: EdgeInsets.all(6),
          child: Text('Phí khám bệnh chuyên khoa', style: style),
        ),
        const Padding(
          padding: EdgeInsets.all(6),
          child: Text('1', style: style, textAlign: TextAlign.center),
        ),
        const Padding(
          padding: EdgeInsets.all(6),
          child: Text('Lần', style: style, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(formattedFee, style: style, textAlign: TextAlign.right),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(formattedFee, style: style, textAlign: TextAlign.right),
        ),
      ],
    );
  }

  TableRow _buildServiceRow(int index, Map<String, dynamic> service) {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.w500);
    final name =
        service['serviceName'] ??
        service['service'] ??
        service['name'] ??
        'Dịch vụ';
    final price = _toMoneyValue(
      service['amount'] ?? service['price'] ?? service['fee'],
    );
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text('$index', style: style, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(name.toString(), style: style),
        ),
        const Padding(
          padding: EdgeInsets.all(6),
          child: Text('1', style: style, textAlign: TextAlign.center),
        ),
        const Padding(
          padding: EdgeInsets.all(6),
          child: Text('Lần', style: style, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            _formatMoney(price.toInt()),
            style: style,
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            _formatMoney(price.toInt()),
            style: style,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  TableRow _buildMedRow(int index, Map<String, dynamic> med) {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.w500);
    final price = _toMoneyValue(med['price']);
    final quantity = _toQuantity(med['quantity']);
    final amount = price * quantity;
    final name = med['name']?.toString() ?? '';
    final unit = med['unit']?.toString() ?? 'Viên';
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text('$index', style: style, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(name, style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            '${med['quantity']}',
            style: style,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(unit, style: style, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            _formatMoney(price.toInt()),
            style: style,
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            _formatMoney(amount.toInt()),
            style: style,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    final total = _effectiveTotalPrice.toInt();
    return Column(
      children: [
        _summaryRow('Tổng chi phí', _formatMoney(total)),
        const Divider(),
        _summaryRow(
          'Số tiền phải thanh toán',
          _formatMoney(total),
          isBold: true,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bằng chữ: ',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
            Expanded(
              child: Text(
                _numberToWords(total),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
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
            Text(
              'Người trả tiền',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 40),
            Text(
              '(Ký, họ tên)',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        Column(
          children: [
            Text(
              'TP. Hồ Chí Minh, Ngày ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bác sĩ điều trị',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              _doctorSignatureLabel,
              style: const TextStyle(
                fontFamily: 'Cursive',
                fontSize: 24,
                color: Color(0xFF0E47B5),
              ),
            ),
            Text(
              _dataText(['doctorName'], fallback: 'Bác sĩ'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  String _formatMoney(dynamic val) {
    return val.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _handlePrint() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đang chuẩn bị bản in...')));
  }
}
