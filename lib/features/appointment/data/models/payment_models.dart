import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String invoiceId;
  final String appointmentId;
  final String patientId;
  final double amount;
  final String status; // 'paid', 'unpaid'
  final String method; // 'CASH', 'BANK', 'E-WALLET'
  final DateTime createdAt;
  final DateTime? paymentDate;

  PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.appointmentId,
    required this.patientId,
    required this.amount,
    required this.status,
    required this.method,
    required this.createdAt,
    this.paymentDate,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      invoiceId: data['invoiceId'] ?? '',
      appointmentId: data['appointmentId'] ?? '',
      patientId: data['patientId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'unpaid',
      method: data['method'] ?? 'CASH',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentDate: (data['paymentDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'amount': amount,
      'status': status,
      'method': method,
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
    };
  }
}
