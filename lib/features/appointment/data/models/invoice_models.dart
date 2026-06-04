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
  final String status; // 'paid', 'unpaid'
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
    required this.status,
    required this.createdAt,
    this.paymentDate,
  });

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceModel(
      id: doc.id,
      appointmentId: data['appointmentId'] ?? '',
      patientId: data['patientId'] ?? '',
      expenseType: data['expenseType'] ?? '',
      serviceContent: data['serviceContent'] ?? '',
      doctorName: data['doctorName'],
      departmentName: data['departmentName'],
      totalAmount: (data['totalAmount'] ?? data['amount'] ?? 0.0).toDouble(),
      discountAmount: (data['discountAmount'] ?? 0.0).toDouble(),
      amount: (data['finalAmount'] ?? data['amount'] ?? 0.0).toDouble(),
      discountPercent:
          int.tryParse(data['discountPercent']?.toString() ?? '0') ?? 0,
      discountType: data['discountType']?.toString() ?? 'none',
      insuranceApplied: data['insuranceApplied'] == true,
      status: data['status'] ?? 'unpaid',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentDate: (data['paymentDate'] as Timestamp?)?.toDate(),
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
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentDate': paymentDate != null
          ? Timestamp.fromDate(paymentDate!)
          : null,
    };
  }
}
