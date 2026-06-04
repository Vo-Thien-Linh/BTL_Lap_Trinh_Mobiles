import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceModel {
  final String id;
  final String appointmentId;
  final String patientId;
  final String expenseType; // 'Tiền khám', 'Xét nghiệm', etc.
  final String serviceContent; // 'Khám Nội', 'Thử máu', etc.
  final String? doctorName;
  final String? departmentName;
  final double totalAmount; // Base price
  final double discountAmount; // Discount or Insurance coverage
  final double amount; // Final price to pay
  final int discountPercent;
  final String discountType;
  final bool insuranceApplied;
  final double paidAmount;
  final double examFee;
  final double serviceTotal;
  final double medicineTotal;
  final List<Map<String, dynamic>> serviceItems;
  final String status; // 'paid', 'pending', 'unpaid'
  final DateTime createdAt;
  final DateTime? paymentDate;

  InvoiceModel({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.expenseType,
    required this.serviceContent,
    this.doctorName,
    this.departmentName,
    this.totalAmount = 0.0,
    this.discountAmount = 0.0,
    required this.amount,
    this.discountPercent = 0,
    this.discountType = 'none',
    this.insuranceApplied = false,
    this.paidAmount = 0.0,
    this.examFee = 0.0,
    this.serviceTotal = 0.0,
    this.medicineTotal = 0.0,
    this.serviceItems = const [],
    required this.status,
    required this.createdAt,
    this.paymentDate,
  });

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final amount = _toDouble(data['finalAmount'] ?? data['amount']);
    final status = data['status']?.toString() ?? 'unpaid';
    final paidAmount = _toDouble(
      data['paidAmount'] ?? data['amountPaid'] ?? data['paid'],
    );
    return InvoiceModel(
      id: doc.id,
      appointmentId: data['appointmentId'] ?? '',
      patientId: data['patientId'] ?? '',
      expenseType: data['expenseType'] ?? '',
      serviceContent: data['serviceContent'] ?? '',
      doctorName: data['doctorName'],
      departmentName: data['departmentName'],
      totalAmount: _toDouble(
        data['totalAmount'] ??
            data['subtotal'] ??
            data['originalAmount'] ??
            data['amount'],
      ),
      discountAmount: _toDouble(data['discountAmount']),
      amount: amount,
      discountPercent:
          int.tryParse(data['discountPercent']?.toString() ?? '0') ?? 0,
      discountType: data['discountType']?.toString() ?? 'none',
      insuranceApplied: data['insuranceApplied'] == true,
      paidAmount: paidAmount > 0
          ? paidAmount
          : status == 'paid'
          ? amount
          : 0.0,
      examFee: _toDouble(data['examFee'] ?? data['consultationFee']),
      serviceTotal: _toDouble(data['serviceTotal']),
      medicineTotal: _toDouble(data['medicineTotal']),
      serviceItems:
          (data['serviceItems'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const [],
      status: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentDate: (data['paymentDate'] as Timestamp?)?.toDate(),
    );
  }

  double get remainingAmount {
    final remaining = amount - paidAmount;
    return remaining > 0 ? remaining : 0.0;
  }

  bool get isEffectivelyPaid => status == 'paid' || remainingAmount <= 0;

  List<MapEntry<String, double>> get chargeBreakdown {
    final items = <MapEntry<String, double>>[];
    if (examFee > 0) items.add(MapEntry('Phí khám', examFee));
    if (serviceTotal > 0) {
      items.add(MapEntry('Dịch vụ / xét nghiệm', serviceTotal));
    }
    if (medicineTotal > 0) items.add(MapEntry('Thuốc', medicineTotal));
    if (items.isEmpty) {
      items.add(
        MapEntry(serviceContent.isEmpty ? expenseType : serviceContent, amount),
      );
    }
    return items;
  }

  InvoiceModel copyWith({
    String? id,
    String? appointmentId,
    String? patientId,
    String? expenseType,
    String? serviceContent,
    String? doctorName,
    String? departmentName,
    double? totalAmount,
    double? discountAmount,
    double? amount,
    int? discountPercent,
    String? discountType,
    bool? insuranceApplied,
    double? paidAmount,
    double? examFee,
    double? serviceTotal,
    double? medicineTotal,
    List<Map<String, dynamic>>? serviceItems,
    String? status,
    DateTime? createdAt,
    DateTime? paymentDate,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      expenseType: expenseType ?? this.expenseType,
      serviceContent: serviceContent ?? this.serviceContent,
      doctorName: doctorName ?? this.doctorName,
      departmentName: departmentName ?? this.departmentName,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      amount: amount ?? this.amount,
      discountPercent: discountPercent ?? this.discountPercent,
      discountType: discountType ?? this.discountType,
      insuranceApplied: insuranceApplied ?? this.insuranceApplied,
      paidAmount: paidAmount ?? this.paidAmount,
      examFee: examFee ?? this.examFee,
      serviceTotal: serviceTotal ?? this.serviceTotal,
      medicineTotal: medicineTotal ?? this.medicineTotal,
      serviceItems: serviceItems ?? this.serviceItems,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'expenseType': expenseType,
      'serviceContent': serviceContent,
      'doctorName': doctorName,
      'departmentName': departmentName,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'amount': amount,
      'finalAmount': amount,
      'discountPercent': discountPercent,
      'discountType': discountType,
      'insuranceApplied': insuranceApplied,
      'paidAmount': paidAmount,
      'examFee': examFee,
      'serviceTotal': serviceTotal,
      'medicineTotal': medicineTotal,
      'serviceItems': serviceItems,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentDate': paymentDate != null
          ? Timestamp.fromDate(paymentDate!)
          : null,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
