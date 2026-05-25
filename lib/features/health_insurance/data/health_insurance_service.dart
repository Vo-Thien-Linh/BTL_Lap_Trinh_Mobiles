import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/health_insurance_validator.dart';

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
  HealthInsuranceService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
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
      updatedAt: _toDateTime(insuranceData?['updatedAt'] ?? userData?['healthInsuranceUpdatedAt']),
      verifiedAt: _toDateTime(insuranceData?['verifiedAt'] ?? userData?['healthInsuranceVerifiedAt']),
      rejectReason: _firstNonEmpty([insuranceData?['rejectReason']], fallback: ''),
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
    final now = FieldValue.serverTimestamp();

    final userUpdate = <String, dynamic>{
      'healthInsuranceNumber': normalized,
      'insuranceNumber': normalized,
      'healthInsuranceStatus': 'pending',
      'healthInsuranceUpdatedAt': now,
    };

    final insuranceRef = _firestore.collection('health_insurances').doc(uid);
    final insuranceSnapshot = await insuranceRef.get();

    final insuranceUpdate = <String, dynamic>{
      'userId': uid,
      'emailAtSubmit': user?.email,
      'insuranceNumber': normalized,
      'status': 'pending',
      'updatedAt': now,
      'verifiedAt': null,
      'verifiedBy': null,
      'rejectReason': null,
    };

    if (!insuranceSnapshot.exists) {
      insuranceUpdate['createdAt'] = now;
    }

    final batch = _firestore.batch();

    // Project đang có cả users và Users, nên ghi cả hai để tránh lệch dữ liệu.
    batch.set(_firestore.collection('users').doc(uid), userUpdate, SetOptions(merge: true));
    batch.set(_firestore.collection('Users').doc(uid), userUpdate, SetOptions(merge: true));
    batch.set(insuranceRef, insuranceUpdate, SetOptions(merge: true));

    await batch.commit();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _getUserSnapshot(String uid) async {
    final lower = await _firestore.collection('users').doc(uid).get();
    if (lower.exists) {
      return lower;
    }

    final upper = await _firestore.collection('Users').doc(uid).get();
    if (upper.exists) {
      return upper;
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
}
