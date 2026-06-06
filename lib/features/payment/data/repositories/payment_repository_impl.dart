import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../../constants.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_model.dart';

class PatientPaymentRepositoryImpl implements PatientPaymentRepository {
  PatientPaymentRepositoryImpl({
    FirebaseFirestore? firestore,
    http.Client? httpClient,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _httpClient = httpClient ?? http.Client();

  final FirebaseFirestore _firestore;
  final http.Client _httpClient;

  static const _paymentCollections = ['Payments', 'payments'];
  static const _invoiceCollections = ['Invoices', 'invoices'];
  static const _patientFields = ['patientId', 'userId', 'patientUid'];

  @override
  Stream<List<PatientPaymentModel>> watchPatientPayments(String patientId) {
    final controller = StreamController<List<PatientPaymentModel>>();
    final items = <String, PatientPaymentModel>{};
    final subscriptions = <StreamSubscription<dynamic>>[];

    void emit() {
      final list = items.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) controller.add(list);
    }

    void putDocs(QuerySnapshot<Map<String, dynamic>> snapshot) {
      for (final doc in snapshot.docs) {
        final payment = PatientPaymentModel.fromFirestore(doc);
        if (_belongsToPatient(payment, patientId)) {
          _putPayment(items, payment);
        }
      }
      emit();
    }

    void putDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
      if (!doc.exists) return;
      final payment = PatientPaymentModel.fromFirestore(doc);
      if (_belongsToPatient(payment, patientId) ||
          payment.patientId.trim().isEmpty) {
        _putPayment(items, payment);
        emit();
      }
    }

    for (final collection in [..._paymentCollections, ..._invoiceCollections]) {
      for (final field in _patientFields) {
        subscriptions.add(
          _firestore
              .collection(collection)
              .where(field, isEqualTo: patientId)
              .snapshots()
              .listen(putDocs, onError: controller.addError),
        );
      }
    }

    subscriptions.add(
      _firestore
          .collection('Appointments')
          .where('patientId', isEqualTo: patientId)
          .snapshots()
          .listen((snapshot) {
            for (final appointment in snapshot.docs) {
              final data = appointment.data();
              final invoiceIds = _candidateIds(data, [
                'invoiceId',
                'lastInvoiceId',
              ]);
              final paymentIds = _candidateIds(data, ['paymentId']);

              for (final id in invoiceIds) {
                for (final collection in _invoiceCollections) {
                  subscriptions.add(
                    _firestore
                        .collection(collection)
                        .doc(id)
                        .snapshots()
                        .listen(putDoc, onError: controller.addError),
                  );
                }
              }

              for (final id in paymentIds) {
                for (final collection in _paymentCollections) {
                  subscriptions.add(
                    _firestore
                        .collection(collection)
                        .doc(id)
                        .snapshots()
                        .listen(putDoc, onError: controller.addError),
                  );
                }
              }
            }
          }, onError: controller.addError),
    );

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  @override
  Stream<PatientPaymentModel?> watchPaymentByPath(String sourcePath) {
    return _firestore.doc(sourcePath).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PatientPaymentModel.fromFirestore(doc);
    });
  }

  @override
  Future<String> createPayosCheckoutLink({
    required PatientPaymentModel payment,
    required String patientId,
  }) async {
    final baseUrl = AppConstants.paymentApiBaseUrl.trim();
    if (baseUrl.isEmpty) {
      throw const PaymentRequestException(
        'Chưa cấu hình địa chỉ máy chủ thanh toán.',
      );
    }

    final backendPaymentId = payment.paymentId.isNotEmpty
        ? payment.paymentId
        : payment.id;
    final paymentId = Uri.encodeComponent(backendPaymentId);
    final endpoint =
        '${baseUrl.replaceAll(RegExp(r"/+$"), '')}/api/payments/$paymentId/payos/create-link';
    final uri = Uri.tryParse(endpoint);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw const PaymentRequestException(
        'Chưa cấu hình địa chỉ máy chủ thanh toán.',
      );
    }

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    late final http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'patientId': patientId,
              'sourceCollection': payment.sourceCollection,
              'sourcePath': payment.sourcePath,
              'paymentId': backendPaymentId,
              'invoiceId': payment.invoiceId,
              'appointmentId': payment.appointmentId,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const PaymentRequestException(
        'Không kết nối được máy chủ thanh toán. Vui lòng kiểm tra Web Admin/backend hoặc ngrok.',
      );
    } on http.ClientException {
      throw const PaymentRequestException(
        'Không kết nối được máy chủ thanh toán. Vui lòng kiểm tra Web Admin/backend hoặc ngrok.',
      );
    } catch (_) {
      throw const PaymentRequestException(
        'Không kết nối được máy chủ thanh toán. Vui lòng kiểm tra Web Admin/backend hoặc ngrok.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentRequestException(
        _extractError(response.statusCode, response.body),
      );
    }

    final decoded = jsonDecode(response.body);
    final checkoutUrl = _findCheckoutUrl(decoded);
    if (checkoutUrl.isEmpty) {
      throw const PaymentRequestException(
        'Không tạo được liên kết thanh toán.',
      );
    }
    return checkoutUrl;
  }

  @override
  Future<void> markPayAtCounter(PatientPaymentModel payment) async {
    final updates = <String, dynamic>{
      'status': 'pay_at_counter',
      'paymentStatus': 'pay_at_counter',
      'method': 'cash',
      'paymentMethod': 'cash',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .doc(payment.sourcePath)
        .set(updates, SetOptions(merge: true));

    if (payment.appointmentId.trim().isNotEmpty) {
      await _firestore
          .collection('Appointments')
          .doc(payment.appointmentId)
          .set({
            'paymentStatus': 'pay_at_counter',
            'paymentMethod': 'cash',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
  }

  bool _belongsToPatient(PatientPaymentModel payment, String patientId) {
    return payment.patientId == patientId;
  }

  void _putPayment(
    Map<String, PatientPaymentModel> items,
    PatientPaymentModel payment,
  ) {
    final key = payment.paymentId.isNotEmpty
        ? payment.paymentId
        : (payment.invoiceId.isNotEmpty
              ? payment.invoiceId
              : payment.sourcePath);
    final existing = items[key];
    if (existing == null || payment.fromInvoice || !existing.fromInvoice) {
      items[key] = payment;
    }
  }

  List<String> _candidateIds(Map<String, dynamic> data, List<String> keys) {
    return keys
        .map((key) => data[key]?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  String _findCheckoutUrl(dynamic value) {
    if (value is Map<String, dynamic>) {
      for (final key in ['checkoutUrl', 'paymentUrl']) {
        final candidate = value[key]?.toString() ?? '';
        if (candidate.startsWith('http')) return candidate;
      }
      for (final nested in value.values) {
        final candidate = _findCheckoutUrl(nested);
        if (candidate.isNotEmpty) return candidate;
      }
    }
    return '';
  }

  String _extractError(int statusCode, String body) {
    switch (statusCode) {
      case 401:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không có quyền thanh toán hóa đơn này.';
      case 404:
        return 'Không tìm thấy hóa đơn thanh toán.';
      case 409:
        return 'Hóa đơn đã được thanh toán hoặc không còn hợp lệ.';
      case 503:
        return 'Máy chủ chưa cấu hình payOS.';
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = (decoded['message'] ?? decoded['error'] ?? '')
            .toString()
            .trim();
        if (_looksLikeMissingPayOsConfig(message)) {
          return 'Máy chủ chưa cấu hình payOS.';
        }
        if (message.isNotEmpty) return message;
      }
    } catch (_) {
      // Keep the raw backend message below.
    }

    if (_looksLikeMissingPayOsConfig(body)) {
      return 'Máy chủ chưa cấu hình payOS.';
    }

    return 'Không tạo được liên kết thanh toán.';
  }

  bool _looksLikeMissingPayOsConfig(String value) {
    final text = value.toLowerCase();
    return text.contains('payos') &&
        (text.contains('thiếu') ||
            text.contains('thieu') ||
            text.contains('config') ||
            text.contains('cấu hình') ||
            text.contains('cau hinh'));
  }
}

class PaymentRequestException implements Exception {
  const PaymentRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
