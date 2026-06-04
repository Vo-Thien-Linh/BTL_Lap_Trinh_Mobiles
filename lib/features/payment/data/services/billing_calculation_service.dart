import 'package:cloud_firestore/cloud_firestore.dart';

class BillingCalculationResult {
  const BillingCalculationResult({
    required this.originalAmount,
    required this.discountAmount,
    required this.discountPercent,
    required this.finalAmount,
    required this.insuranceApplied,
    required this.insuranceCoveragePercent,
    required this.insuranceCoveredAmount,
    required this.patientPayAmount,
    required this.discountType,
    required this.discountSource,
    this.insuranceNumber,
    this.insuranceCode,
    this.insuranceStatusAtBilling,
    this.insuranceExpiryAtBilling,
  });

  final double originalAmount;
  final double discountAmount;
  final int discountPercent;
  final double finalAmount;
  final bool insuranceApplied;
  final int insuranceCoveragePercent;
  final double insuranceCoveredAmount;
  final double patientPayAmount;
  final String discountType;
  final String discountSource;
  final String? insuranceNumber;
  final String? insuranceCode;
  final String? insuranceStatusAtBilling;
  final DateTime? insuranceExpiryAtBilling;

  Map<String, dynamic> toFirestoreFields() {
    return {
      'originalAmount': originalAmount,
      'subtotal': originalAmount,
      'totalAmount': originalAmount,
      'discount': discountAmount,
      'discountAmount': discountAmount,
      'discountPercent': discountPercent,
      'discountType': discountType,
      'discountSource': discountSource,
      'insuranceApplied': insuranceApplied,
      'insuranceCoveragePercent': insuranceCoveragePercent,
      'insuranceCoveredAmount': insuranceCoveredAmount,
      'patientPayAmount': patientPayAmount,
      'insuranceNumber': insuranceNumber,
      'insuranceCode': insuranceCode,
      'insuranceStatusAtBilling': insuranceStatusAtBilling,
      'insuranceExpiryAtBilling': insuranceExpiryAtBilling == null
          ? null
          : Timestamp.fromDate(insuranceExpiryAtBilling!),
      'amount': finalAmount,
      'total': finalAmount,
      'finalAmount': finalAmount,
    };
  }
}

class BillingCalculationService {
  BillingCalculationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int healthInsuranceCoveragePercent = 80;

  final FirebaseFirestore _firestore;

  Future<BillingCalculationResult> calculate({
    required String patientId,
    required double originalAmount,
  }) async {
    final insurance = await _loadInsurance(patientId);
    final canApplyInsurance =
        insurance.number.isNotEmpty &&
        _isDiscountEligibleStatus(insurance.status) &&
        _isNotExpired(insurance.expiryDate);
    final insuranceCoveredAmount = canApplyInsurance
        ? (originalAmount * healthInsuranceCoveragePercent / 100)
              .roundToDouble()
        : 0.0;
    final patientPayAmount = (originalAmount - insuranceCoveredAmount)
        .clamp(0.0, double.infinity)
        .toDouble();

    return BillingCalculationResult(
      originalAmount: originalAmount,
      discountAmount: insuranceCoveredAmount,
      discountPercent: canApplyInsurance ? healthInsuranceCoveragePercent : 0,
      finalAmount: patientPayAmount,
      insuranceApplied: canApplyInsurance,
      insuranceCoveragePercent: canApplyInsurance
          ? healthInsuranceCoveragePercent
          : 0,
      insuranceCoveredAmount: insuranceCoveredAmount,
      patientPayAmount: patientPayAmount,
      discountType: canApplyInsurance ? 'health_insurance' : 'none',
      discountSource: canApplyInsurance ? 'BHYT' : 'none',
      insuranceNumber: insurance.number.isEmpty ? null : insurance.number,
      insuranceCode: insurance.code.isEmpty ? null : insurance.code,
      insuranceStatusAtBilling: insurance.status.isEmpty
          ? null
          : insurance.status,
      insuranceExpiryAtBilling: insurance.expiryDate,
    );
  }

  Future<_InsuranceSnapshot> _loadInsurance(String patientId) async {
    final userData = await _getUserData(patientId);
    final insuranceDoc = await _firestore
        .collection('health_insurances')
        .doc(patientId)
        .get();
    final insuranceData = insuranceDoc.data();

    return _InsuranceSnapshot(
      number: _firstNonEmpty([
        insuranceData?['insuranceNumber'],
        insuranceData?['healthInsuranceNumber'],
        userData?['healthInsuranceNumber'],
        userData?['insuranceNumber'],
      ]),
      status: _firstNonEmpty([
        insuranceData?['status'],
        insuranceData?['healthInsuranceStatus'],
        userData?['healthInsuranceStatus'],
        userData?['insuranceStatus'],
      ]),
      code: _firstNonEmpty([
        insuranceData?['insuranceCode'],
        userData?['insuranceCode'],
      ]),
      expiryDate: _toDateTime(
        insuranceData?['expiryDate'] ??
            insuranceData?['healthInsuranceExpiryDate'] ??
            insuranceData?['insuranceExpiryDate'] ??
            userData?['healthInsuranceExpiryDate'] ??
            userData?['insuranceExpiryDate'] ??
            userData?['expiryDate'],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserData(String patientId) async {
    if (patientId.trim().isEmpty) return null;

    final lowerDoc = await _firestore.collection('users').doc(patientId).get();
    if (lowerDoc.exists) return lowerDoc.data();

    final upperDoc = await _firestore.collection('Users').doc(patientId).get();
    if (upperDoc.exists) return upperDoc.data();

    final uidSnapshot = await _firestore
        .collection('users')
        .where('uid', isEqualTo: patientId)
        .limit(1)
        .get();
    if (uidSnapshot.docs.isNotEmpty) return uidSnapshot.docs.first.data();

    return null;
  }

  bool _isDiscountEligibleStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'active' ||
        normalized == 'approved' ||
        normalized == 'verified';
  }

  bool _isNotExpired(DateTime? expiryDate) {
    if (expiryDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    return !expiryDay.isBefore(today);
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class _InsuranceSnapshot {
  const _InsuranceSnapshot({
    required this.number,
    required this.status,
    required this.code,
    required this.expiryDate,
  });

  final String number;
  final String status;
  final String code;
  final DateTime? expiryDate;
}
