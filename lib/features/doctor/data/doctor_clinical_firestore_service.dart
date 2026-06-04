import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorClinicalFirestoreService {
  DoctorClinicalFirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<String> completeExamination({
    required String appointmentId,
    required Map<String, dynamic> appointmentData,
    required String symptoms,
    required String physicalExam,
    required String diagnosis,
    required String treatment,
    required String notes,
    required Map<String, dynamic> vitals,
    required List<Map<String, dynamic>> services,
  }) async {
    final appointmentRef = _firestore
        .collection('Appointments')
        .doc(appointmentId);
    final recordRef = _firestore
        .collection('MedicalRecords')
        .doc(appointmentId);
    final labOrderRef = _firestore.collection('LabOrders').doc(appointmentId);

    final patientId = _text(appointmentData, ['patientId', 'userId']);
    final doctorId = _text(appointmentData, [
      'doctorId',
    ], fallback: _currentUserId ?? '');
    final departmentId = _text(appointmentData, ['departmentId']);
    final now = FieldValue.serverTimestamp();

    final recordData = <String, dynamic>{
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': _text(appointmentData, ['patientName', 'name']),
      'doctorId': doctorId,
      'doctorName': _text(appointmentData, ['doctorName']),
      'departmentId': departmentId,
      'departmentName': _text(appointmentData, ['departmentName']),
      'scheduleId': _text(appointmentData, ['scheduleId']),
      'shiftId': _text(appointmentData, ['shiftId']),
      'roomNumber': _text(appointmentData, ['roomNumber']),
      'appointmentDate': appointmentData['appointmentDate'],
      'symptoms': symptoms,
      'physicalExam': physicalExam,
      'diagnosis': diagnosis,
      'clinicalNotes': physicalExam,
      'treatment': treatment,
      'conclusion': treatment,
      'notes': notes,
      'vitals': vitals,
      'serviceItems': services,
      'status': 'completed',
      'updatedAt': now,
    };

    final batch = _firestore.batch();
    batch.set(recordRef, {
      ...recordData,
      'createdAt': now,
    }, SetOptions(merge: true));

    batch.update(appointmentRef, {
      'status': 'completed',
      'completedAt': now,
      'medicalRecordId': recordRef.id,
      'symptoms': symptoms,
      'physicalExam': physicalExam,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'notes': notes,
      'vitals': vitals,
      'services': services,
      'updatedAt': now,
    });

    if (services.isNotEmpty) {
      batch.set(labOrderRef, {
        'appointmentId': appointmentId,
        'medicalRecordId': recordRef.id,
        'patientId': patientId,
        'patientName': _text(appointmentData, ['patientName', 'name']),
        'doctorId': doctorId,
        'doctorName': _text(appointmentData, ['doctorName']),
        'departmentId': departmentId,
        'departmentName': _text(appointmentData, ['departmentName']),
        'testItems': services,
        'status': 'ordered',
        'orderedAt': now,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      batch.update(appointmentRef, {'lastLabOrderId': labOrderRef.id});
    }

    await batch.commit();
    return recordRef.id;
  }

  Future<String> savePrescription({
    required String appointmentId,
    required Map<String, dynamic> patientData,
    required List<Map<String, dynamic>> medicines,
    String? medicalRecordId,
    String notes = '',
  }) async {
    final appointmentRef = _firestore
        .collection('Appointments')
        .doc(appointmentId);
    final prescriptionRef = _firestore
        .collection('Prescriptions')
        .doc(appointmentId);
    final appointmentSnapshot = await appointmentRef.get();
    final effectivePatientData = {
      ...(appointmentSnapshot.data() ?? const <String, dynamic>{}),
      ...patientData,
    };
    final patientId = _text(effectivePatientData, [
      'patientId',
      'userId',
      'uid',
      'id',
    ]);
    if (patientId.isEmpty) {
      throw Exception('Không xác định được bệnh nhân để lưu đơn thuốc.');
    }
    final doctorId = _text(effectivePatientData, [
      'doctorId',
    ], fallback: _currentUserId ?? '');
    final now = FieldValue.serverTimestamp();

    final data = {
      'appointmentId': appointmentId,
      'medicalRecordId':
          medicalRecordId ?? _text(effectivePatientData, ['medicalRecordId']),
      'patientId': patientId,
      'patientName': _text(effectivePatientData, [
        'patientName',
        'fullName',
        'name',
      ]),
      'doctorId': doctorId,
      'doctorName': _text(effectivePatientData, ['doctorName']),
      'departmentId': _text(effectivePatientData, ['departmentId']),
      'departmentName': _text(effectivePatientData, ['departmentName']),
      'medicines': medicines,
      'notes': notes,
      'status': 'active',
      'createdAt': now,
      'updatedAt': now,
    };

    final batch = _firestore.batch();
    batch.set(prescriptionRef, data, SetOptions(merge: true));
    batch.set(appointmentRef, {
      'patientId': patientId,
      'prescriptionId': prescriptionRef.id,
      'medicalRecordId': data['medicalRecordId'],
      'prescription': medicines,
      'updatedAt': now,
    }, SetOptions(merge: true));

    final effectiveMedicalRecordId = data['medicalRecordId']?.toString() ?? '';
    if (effectiveMedicalRecordId.isNotEmpty) {
      batch.set(
        _firestore.collection('MedicalRecords').doc(effectiveMedicalRecordId),
        {
          'prescriptionId': prescriptionRef.id,
          'prescription': medicines,
          'medicines': medicines,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    return prescriptionRef.id;
  }

  Future<String> saveLabResult({
    required String labOrderId,
    required Map<String, dynamic> orderData,
    required List<Map<String, dynamic>> resultItems,
    List<String> resultFileUrls = const [],
    String conclusion = '',
  }) async {
    final resultRef = _firestore.collection('LabResults').doc(labOrderId);
    final orderRef = _firestore.collection('LabOrders').doc(labOrderId);
    final appointmentId = _text(orderData, ['appointmentId']);
    final appointmentRef = _firestore
        .collection('Appointments')
        .doc(appointmentId);
    final now = FieldValue.serverTimestamp();

    final batch = _firestore.batch();
    batch.set(resultRef, {
      'labOrderId': labOrderId,
      'appointmentId': appointmentId,
      'medicalRecordId': _text(orderData, ['medicalRecordId']),
      'patientId': _text(orderData, ['patientId']),
      'doctorId': _text(orderData, ['doctorId']),
      'resultItems': resultItems,
      'resultFileUrls': resultFileUrls,
      'conclusion': conclusion,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
    batch.update(orderRef, {
      'status': 'completed',
      'labResultId': resultRef.id,
      'completedAt': now,
      'updatedAt': now,
    });
    if (appointmentId.isNotEmpty) {
      batch.set(appointmentRef, {
        'labResultIds': FieldValue.arrayUnion([resultRef.id]),
        'updatedAt': now,
      }, SetOptions(merge: true));
    }
    await batch.commit();
    return resultRef.id;
  }

  static String _text(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }
}
