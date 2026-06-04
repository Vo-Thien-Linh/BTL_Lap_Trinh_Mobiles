import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String invoiceId;
  final String appointmentId;
  final String patientId;
  final double amount;
  final String status; // 'pending', 'paid', 'failed', 'refunded'
  final String method; // App writes 'bank_transfer'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final String? confirmedBy;
  final DateTime? confirmedAt;

  PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.appointmentId,
    required this.patientId,
    required this.amount,
    required this.status,
    required this.method,
    required this.createdAt,
    this.updatedAt,
    this.paidAt,
    this.confirmedBy,
    this.confirmedAt,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      invoiceId: data['invoiceId'] ?? '',
      appointmentId: data['appointmentId'] ?? '',
      patientId: data['patientId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      method: data['method'] ?? 'bank_transfer',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      paidAt:
          (data['paidAt'] as Timestamp?)?.toDate() ??
          (data['paymentDate'] as Timestamp?)?.toDate(),
      confirmedBy: data['confirmedBy']?.toString(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
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
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'confirmedBy': confirmedBy,
      'confirmedAt': confirmedAt != null
          ? Timestamp.fromDate(confirmedAt!)
          : null,
    };
  }
}
