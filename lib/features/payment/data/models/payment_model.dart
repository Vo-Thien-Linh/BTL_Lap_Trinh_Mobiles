import 'package:cloud_firestore/cloud_firestore.dart';

class PatientPaymentModel {
  final String id;
  final String sourceCollection;
  final String sourcePath;
  final bool fromInvoice;
  final String paymentId;
  final String invoiceId;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  final String specialtyName;
  final DateTime? appointmentDate;
  final double amount;
  final double totalAmount;
  final double discountAmount;
  final String currency;
  final String paymentCode;
  final String invoiceCode;
  final String discountType;
  final bool insuranceApplied;
  final int insuranceCoveragePercent;
  final double insuranceCoveredAmount;
  final double patientPayAmount;
  final String status;
  final String paymentMethod;
  final String gatewayProvider;
  final String gatewayOrderCode;
  final String gatewayTransactionId;
  final String checkoutUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final String note;
  final String serviceContent;
  final String expenseType;

  const PatientPaymentModel({
    required this.id,
    required this.sourceCollection,
    required this.sourcePath,
    required this.fromInvoice,
    required this.paymentId,
    required this.invoiceId,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    required this.specialtyName,
    required this.appointmentDate,
    required this.amount,
    required this.totalAmount,
    required this.discountAmount,
    required this.currency,
    required this.paymentCode,
    required this.invoiceCode,
    required this.discountType,
    required this.insuranceApplied,
    required this.insuranceCoveragePercent,
    required this.insuranceCoveredAmount,
    required this.patientPayAmount,
    required this.status,
    required this.paymentMethod,
    required this.gatewayProvider,
    required this.gatewayOrderCode,
    required this.gatewayTransactionId,
    required this.checkoutUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.paidAt,
    required this.note,
    required this.serviceContent,
    required this.expenseType,
  });

  factory PatientPaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final collection = doc.reference.parent.id;
    final isInvoice = collection.toLowerCase().contains('invoice');
    final rawStatus = _readString(data, ['paymentStatus', 'status']);
    final rawMethod = _readString(data, ['paymentMethod', 'method']);
    final amount = _readDouble(data, [
      'patientPayAmount',
      'finalAmount',
      'amountDue',
      'payableAmount',
      'amount',
      'total',
      'totalAmount',
      'subtotal',
    ]);
    final totalAmount = _readDouble(data, [
      'originalAmount',
      'totalAmount',
      'total',
      'subtotal',
    ]);
    final paidAt = _readDate(data, ['paidAt', 'paymentDate']);
    final insuranceApplied =
        data['insuranceApplied'] == true ||
        _readString(data, ['discountType']) == 'health_insurance';
    final insuranceCoveragePercent = _readInt(data, [
      'insuranceCoveragePercent',
      'discountPercent',
    ]);
    final insuranceCoveredAmount = _readDouble(data, [
      'insuranceCoveredAmount',
      'discountAmount',
      'discount',
    ]);

    return PatientPaymentModel(
      id: doc.id,
      sourceCollection: collection,
      sourcePath: doc.reference.path,
      fromInvoice: isInvoice,
      paymentId: isInvoice ? _readString(data, ['paymentId']) : doc.id,
      invoiceId: isInvoice ? doc.id : _readString(data, ['invoiceId']),
      appointmentId: _readString(data, ['appointmentId']),
      patientId: _readString(data, ['patientId', 'userId', 'patientUid']),
      doctorId: _readString(data, ['doctorId']),
      patientName: _readString(data, ['patientName', 'customerName']),
      doctorName: _readString(data, ['doctorName']),
      specialtyName: _readString(data, [
        'specialtyName',
        'departmentName',
        'department',
      ]),
      appointmentDate: _readDate(data, ['appointmentDate', 'examDate']),
      amount: amount,
      totalAmount: totalAmount == 0 ? amount : totalAmount,
      discountAmount: _readDouble(data, ['discountAmount', 'discount']),
      currency: _readString(data, ['currency']).isEmpty
          ? 'VND'
          : _readString(data, ['currency']),
      paymentCode:
          _readString(data, [
            'paymentCode',
            'invoiceCode',
            'code',
            'id',
          ]).isEmpty
          ? doc.id
          : _readString(data, ['paymentCode', 'invoiceCode', 'code', 'id']),
      invoiceCode: _readString(data, ['invoiceCode', 'receiptCode']),
      discountType: _readString(data, ['discountType']),
      insuranceApplied: insuranceApplied,
      insuranceCoveragePercent: insuranceApplied
          ? (insuranceCoveragePercent == 0 ? 80 : insuranceCoveragePercent)
          : 0,
      insuranceCoveredAmount: insuranceApplied ? insuranceCoveredAmount : 0,
      patientPayAmount: _readDouble(data, [
        'patientPayAmount',
        'finalAmount',
        'amountDue',
        'payableAmount',
        'amount',
      ]),
      status: normalizeStatus(rawStatus),
      paymentMethod: normalizeMethod(rawMethod),
      gatewayProvider: _readString(data, ['gatewayProvider', 'provider']),
      gatewayOrderCode: _readString(data, ['gatewayOrderCode', 'orderCode']),
      gatewayTransactionId: _readString(data, [
        'gatewayTransactionId',
        'transactionId',
      ]),
      checkoutUrl: _readString(data, ['checkoutUrl', 'paymentUrl']),
      createdAt:
          _readDate(data, ['createdAt', 'issuedAt']) ??
          paidAt ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: _readDate(data, ['updatedAt']),
      paidAt: paidAt,
      note: _readString(data, ['note', 'description']),
      serviceContent: _readString(data, [
        'serviceContent',
        'description',
        'content',
      ]),
      expenseType: _readString(data, ['expenseType', 'type']),
    );
  }

  bool get isPaid => status == 'paid';
  bool get canStartPayos =>
      const {'unpaid', 'pending', 'failed', 'expired'}.contains(status);
  bool get canChooseCash =>
      const {'unpaid', 'pending', 'failed', 'expired'}.contains(status);
  bool get isProcessing => const {
    'payos_pending',
    'qr_generated',
    'waiting_confirmation',
  }.contains(status);

  PatientPaymentModel copyWithCheckout(String url) {
    return PatientPaymentModel(
      id: id,
      sourceCollection: sourceCollection,
      sourcePath: sourcePath,
      fromInvoice: fromInvoice,
      paymentId: paymentId,
      invoiceId: invoiceId,
      appointmentId: appointmentId,
      patientId: patientId,
      doctorId: doctorId,
      patientName: patientName,
      doctorName: doctorName,
      specialtyName: specialtyName,
      appointmentDate: appointmentDate,
      amount: amount,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      currency: currency,
      paymentCode: paymentCode,
      invoiceCode: invoiceCode,
      discountType: discountType,
      insuranceApplied: insuranceApplied,
      insuranceCoveragePercent: insuranceCoveragePercent,
      insuranceCoveredAmount: insuranceCoveredAmount,
      patientPayAmount: patientPayAmount,
      status: status,
      paymentMethod: paymentMethod,
      gatewayProvider: gatewayProvider,
      gatewayOrderCode: gatewayOrderCode,
      gatewayTransactionId: gatewayTransactionId,
      checkoutUrl: url,
      createdAt: createdAt,
      updatedAt: updatedAt,
      paidAt: paidAt,
      note: note,
      serviceContent: serviceContent,
      expenseType: expenseType,
    );
  }

  static String normalizeStatus(String value) {
    final status = value.trim().toLowerCase();
    switch (status) {
      case '':
      case 'new':
      case 'created':
      case 'not_paid':
        return 'unpaid';
      case 'cash':
      case 'counter':
      case 'pay-at-counter':
        return 'pay_at_counter';
      case 'bank':
      case 'transfer_pending':
      case 'confirming':
        return 'waiting_confirmation';
      case 'qr_generated':
      case 'payos':
        return 'payos_pending';
      case 'success':
      case 'completed':
      case 'confirmed':
        return 'paid';
      default:
        return status;
    }
  }

  static String normalizeMethod(String value) {
    final method = value.trim().toLowerCase();
    switch (method) {
      case 'cash':
      case 'tien mat':
      case 'tiền mặt':
        return 'cash';
      case 'bank':
      case 'transfer':
      case 'chuyen khoan':
      case 'chuyển khoản':
        return 'bank';
      case 'wallet':
      case 'e-wallet':
        return 'wallet';
      case 'payos':
        return 'payos';
      default:
        return method;
    }
  }

  static String _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static double _readDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static int _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static DateTime? _readDate(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
