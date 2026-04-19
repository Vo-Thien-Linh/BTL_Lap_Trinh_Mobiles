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
      amount: (data['amount'] ?? 0.0).toDouble(),
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
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
    };
  }
}
