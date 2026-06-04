import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSequenceConfig {
  const FirestoreSequenceConfig({
    required this.counterId,
    required this.prefix,
    this.padding = 6,
  });

  final String counterId;
  final String prefix;
  final int padding;
}

class FirestoreSequenceService {
  FirestoreSequenceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const countersCollection = 'system_counters';

  static const Map<String, FirestoreSequenceConfig> configs = {
    'patients': FirestoreSequenceConfig(
      counterId: 'patients',
      prefix: 'PATIENT',
    ),
    'doctors': FirestoreSequenceConfig(counterId: 'doctors', prefix: 'DOCTOR'),
    'appointments': FirestoreSequenceConfig(
      counterId: 'appointments',
      prefix: 'APPOINTMENT',
    ),
    'payments': FirestoreSequenceConfig(
      counterId: 'payments',
      prefix: 'PAYMENT',
    ),
    'invoices': FirestoreSequenceConfig(
      counterId: 'invoices',
      prefix: 'INVOICE',
    ),
    'prescriptions': FirestoreSequenceConfig(
      counterId: 'prescriptions',
      prefix: 'PRESCRIPTION',
    ),
    'insurance': FirestoreSequenceConfig(
      counterId: 'insurance',
      prefix: 'INSURANCE',
    ),
    'cancel_requests': FirestoreSequenceConfig(
      counterId: 'cancel_requests',
      prefix: 'CANCEL-REQUEST',
    ),
    'notifications': FirestoreSequenceConfig(
      counterId: 'notifications',
      prefix: 'NOTIFICATION',
    ),
  };

  Future<String> generateNextCode(String entityType) {
    return _firestore.runTransaction((transaction) async {
      return generateNextCodeInTransaction(
        transaction: transaction,
        firestore: _firestore,
        entityType: entityType,
      );
    });
  }

  static Future<String> generateNextCodeInTransaction({
    required Transaction transaction,
    required FirebaseFirestore firestore,
    required String entityType,
  }) async {
    final config = configs[entityType];
    if (config == null) {
      throw ArgumentError('Unknown sequence entity type: $entityType');
    }

    final ref = firestore.collection(countersCollection).doc(config.counterId);
    final snapshot = await transaction.get(ref);
    final data = snapshot.data() ?? const <String, dynamic>{};
    final prefix = (data['prefix']?.toString().trim().isNotEmpty ?? false)
        ? data['prefix'].toString().trim()
        : config.prefix;
    final padding =
        int.tryParse(data['padding']?.toString() ?? '') ?? config.padding;
    final current = int.tryParse(data['currentNumber']?.toString() ?? '') ?? 0;
    final next = current + 1;

    transaction.set(ref, {
      'prefix': prefix,
      'padding': padding,
      'currentNumber': next,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return '$prefix-${next.toString().padLeft(padding, '0')}';
  }
}
