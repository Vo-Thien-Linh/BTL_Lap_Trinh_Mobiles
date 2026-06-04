import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/health_insurance_validator.dart';
import '../../../services/firestore_sequence_service.dart';

class HealthInsuranceInfo {
  const HealthInsuranceInfo({
    required this.number,
    required this.status,
    this.updatedAt,
    this.verifiedAt,
    this.rejectReason,
  });

  final String number;
  final String status;
  final DateTime? updatedAt;
  final DateTime? verifiedAt;
  final String? rejectReason;

  bool get hasNumber => number.trim().isNotEmpty;

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Chờ xác minh';
      case 'approved':
      case 'verified':
        return 'Đã xác minh';
      case 'rejected':
        return 'Không hợp lệ';
      case 'unverified':
      default:
        return 'Chưa xác minh';
    }
  }
}

class HealthInsuranceService {
  HealthInsuranceService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Người dùng chưa đăng nhập');
    }
    return user.uid;
  }

  Future<HealthInsuranceInfo?> getCurrentInsurance() async {
    final uid = _uid;

    final userDoc = await _getUserSnapshot(uid);
    final userData = userDoc?.data();

    final insuranceDoc = await _firestore
        .collection('health_insurances')
        .doc(uid)
        .get();
    final insuranceData = insuranceDoc.data();

    final number = _firstNonEmpty([
      insuranceData?['insuranceNumber'],
      userData?['healthInsuranceNumber'],
      userData?['insuranceNumber'],
      userData?['healthInsuranceNumber'],
    ]);

    if (number.isEmpty) {
      return null;
    }

    final status = _firstNonEmpty([
      insuranceData?['status'],
      userData?['healthInsuranceStatus'],
      userData?['insuranceStatus'],
    ], fallback: 'unverified');

    return HealthInsuranceInfo(
      number: number,
      status: status,
      updatedAt: _toDateTime(
        insuranceData?['updatedAt'] ?? userData?['healthInsuranceUpdatedAt'],
      ),
      verifiedAt: _toDateTime(
        insuranceData?['verifiedAt'] ?? userData?['healthInsuranceVerifiedAt'],
      ),
      rejectReason: _firstNonEmpty([
        insuranceData?['rejectReason'],
      ], fallback: ''),
    );
  }

  Future<void> saveInsuranceNumber(String value) async {
    final uid = _uid;
    final normalized = HealthInsuranceValidator.normalize(value);
    final validationError = HealthInsuranceValidator.validate(normalized);

    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final user = _auth.currentUser;
    final userRef = _firestore.collection('users').doc(uid);
    final insuranceRef = _firestore.collection('health_insurances').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final insuranceSnapshot = await transaction.get(insuranceRef);
      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final insuranceData =
          insuranceSnapshot.data() ?? const <String, dynamic>{};
      final currentStatus = _firstNonEmpty([
        insuranceData['status'],
        userData['healthInsuranceStatus'],
        userData['insuranceStatus'],
      ]);
      final currentExpiry = _toDateTime(
        insuranceData['expiryDate'] ??
            userData['healthInsuranceExpiryDate'] ??
            userData['insuranceExpiryDate'],
      );
      final hasActiveInsurance = _isActiveInsurance(
        currentStatus,
        currentExpiry,
      );
      final now = FieldValue.serverTimestamp();
      final existingCode = _firstNonEmpty([
        insuranceData['insuranceCode'],
        userData['insuranceCode'],
      ]);
      final insuranceCode = existingCode.isNotEmpty
          ? existingCode
          : await FirestoreSequenceService.generateNextCodeInTransaction(
              transaction: transaction,
              firestore: _firestore,
              entityType: 'insurance',
            );

      final userUpdate = <String, dynamic>{
        'insuranceCode': insuranceCode,
        'healthInsuranceUpdatedAt': now,
        'pendingHealthInsuranceNumber': normalized,
        'pendingHealthInsuranceSubmittedAt': now,
        'pendingHealthInsuranceStatus': 'pending',
        'pendingHealthInsuranceRejectReason': null,
      };

      if (!hasActiveInsurance) {
        userUpdate.addAll({
          'healthInsuranceNumber': normalized,
          'insuranceNumber': normalized,
          'healthInsuranceStatus': 'pending',
          'insuranceStatus': 'pending',
        });
      } else {
        userUpdate.addAll({
          'previousApprovedHealthInsuranceNumber': _firstNonEmpty([
            userData['healthInsuranceNumber'],
            insuranceData['insuranceNumber'],
          ]),
          'previousApprovedHealthInsuranceExpiryDate': currentExpiry == null
              ? null
              : Timestamp.fromDate(currentExpiry),
          'previousApprovedHealthInsuranceStatus': currentStatus,
        });
      }

      final insuranceUpdate = <String, dynamic>{
        'insuranceCode': insuranceCode,
        'userId': uid,
        'emailAtSubmit': user?.email,
        'pendingInsuranceNumber': normalized,
        'pendingHealthInsuranceNumber': normalized,
        'pendingHealthInsuranceStatus': 'pending',
        'status': hasActiveInsurance ? currentStatus : 'pending',
        'updatedAt': now,
        'verifiedAt': insuranceData['verifiedAt'],
        'verifiedBy': insuranceData['verifiedBy'],
        'rejectReason': null,
      };

      if (!hasActiveInsurance) {
        insuranceUpdate['insuranceNumber'] = normalized;
      }
      if (!insuranceSnapshot.exists) {
        insuranceUpdate['createdAt'] = now;
      }

      transaction.set(userRef, userUpdate, SetOptions(merge: true));
      transaction.set(insuranceRef, insuranceUpdate, SetOptions(merge: true));
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _getUserSnapshot(
    String uid,
  ) async {
    final lower = await _firestore.collection('users').doc(uid).get();
    if (lower.exists) {
      return lower;
    }

    return null;
  }

  static String _firstNonEmpty(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static bool _isActiveInsurance(String status, DateTime? expiryDate) {
    final normalized = status.trim().toLowerCase();
    final statusActive =
        normalized == 'active' ||
        normalized == 'approved' ||
        normalized == 'verified';
    if (!statusActive) return false;
    if (expiryDate == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    ).isBefore(today);
  }
}
