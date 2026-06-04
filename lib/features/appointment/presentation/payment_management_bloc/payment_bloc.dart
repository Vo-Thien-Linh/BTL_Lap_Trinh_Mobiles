import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/invoice_models.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _invoiceSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _paymentSubscription;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _latestInvoiceDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _latestPaymentDocs = [];

  PaymentBloc() : super(const PaymentState()) {
    on<LoadInvoices>(_onLoadInvoices);
    on<UpdateInvoicesList>(_onUpdateInvoicesList);
    on<FilterInvoices>(_onFilterInvoices);
    on<ProcessPayment>(_onProcessPayment);
    on<RefreshInvoices>(_onRefreshInvoices);
  }

  @override
  Future<void> close() {
    _invoiceSubscription?.cancel();
    _paymentSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadInvoices(
    LoadInvoices event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(status: PaymentStatus.loading));

    await _invoiceSubscription?.cancel();
    await _paymentSubscription?.cancel();

    _invoiceSubscription = _firestore
        .collection('Invoices')
        .where('patientId', isEqualTo: event.patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _latestInvoiceDocs = snapshot.docs;
          _publishLatestInvoices();
        });

    _paymentSubscription = _firestore
        .collection('Payments')
        .where('patientId', isEqualTo: event.patientId)
        .snapshots()
        .listen((snapshot) {
          _latestPaymentDocs = snapshot.docs;
          _publishLatestInvoices();
        });
  }

  void _publishLatestInvoices() {
    final invoices = _latestInvoiceDocs.map((doc) {
      final invoice = InvoiceModel.fromFirestore(doc);
      return _invoiceWithPaymentStatus(invoice);
    }).toList();

    add(UpdateInvoicesList(invoices));
  }

  InvoiceModel _invoiceWithPaymentStatus(InvoiceModel invoice) {
    final relatedPayments = _latestPaymentDocs
        .where((doc) => doc.data()['invoiceId']?.toString() == invoice.id)
        .map((doc) => doc.data())
        .toList();

    final paidAmount = relatedPayments
        .where((payment) => payment['status']?.toString() == 'paid')
        .fold<double>(
          invoice.status == 'paid' ? invoice.amount : 0.0,
          (total, payment) => total + _toDouble(payment['amount']),
        );
    final hasPending = relatedPayments.any(
      (payment) => payment['status']?.toString() == 'pending',
    );
    final status = paidAmount >= invoice.amount && invoice.amount > 0
        ? 'paid'
        : hasPending
        ? 'pending'
        : invoice.status;

    return invoice.copyWith(status: status, paidAmount: paidAmount);
  }

  void _onUpdateInvoicesList(
    UpdateInvoicesList event,
    Emitter<PaymentState> emit,
  ) {
    emit(
      state.copyWith(
        status: PaymentStatus.success,
        allInvoices: event.invoices,
        filteredInvoices: _applyFilters(
          event.invoices,
          state.selectedStatus,
          state.selectedType,
        ),
      ),
    );
  }

  List<InvoiceModel> _applyFilters(
    List<InvoiceModel> all,
    String? status,
    String? type,
  ) {
    final currentStatus = status ?? 'Tất cả trạng thái';
    final currentType = type ?? 'Tất cả loại';
    var filtered = all;

    if (currentStatus != 'Tất cả trạng thái') {
      const statusMap = {
        'Đã thanh toán': 'paid',
        'Chờ duyệt': 'pending',
        'Chưa thanh toán': 'unpaid',
      };
      filtered = filtered
          .where((invoice) => invoice.status == statusMap[currentStatus])
          .toList();
    }

    if (currentType != 'Tất cả loại') {
      filtered = filtered
          .where((invoice) => invoice.expenseType == currentType)
          .toList();
    }

    return filtered;
  }

  void _onFilterInvoices(FilterInvoices event, Emitter<PaymentState> emit) {
    final status = event.status ?? state.selectedStatus ?? 'Tất cả trạng thái';
    final type = event.type ?? state.selectedType ?? 'Tất cả loại';

    emit(
      state.copyWith(
        filteredInvoices: _applyFilters(state.allInvoices, status, type),
        selectedStatus: status,
        selectedType: type,
      ),
    );
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(status: PaymentStatus.processing));
    try {
      final now = Timestamp.now();
      final paymentMethod = _normalizePaymentMethod(event.paymentMethod);
      final batch = _firestore.batch();

      batch.set(
        _firestore.collection('Invoices').doc(event.invoiceId),
        {
          'status': 'pending',
          'paymentStatus': 'pending',
          'paymentMethod': paymentMethod,
          'paymentConfirmedByPatientAt': now,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      final paymentSnapshot = await _firestore
          .collection('Payments')
          .where('invoiceId', isEqualTo: event.invoiceId)
          .limit(1)
          .get();
      final paymentRef = paymentSnapshot.docs.isNotEmpty
          ? paymentSnapshot.docs.first.reference
          : _firestore.collection('Payments').doc();

      batch.set(paymentRef, {
        'appointmentId': event.appointmentId,
        'invoiceId': event.invoiceId,
        'patientId': event.patientId,
        'amount': event.amount,
        'method': paymentMethod,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'paymentStatus': 'pending',
        'paidAt': null,
        'confirmedBy': 'patient',
        'confirmedAt': now,
        'updatedAt': now,
        if (paymentSnapshot.docs.isEmpty) 'createdAt': now,
      }, SetOptions(merge: true));

      batch.set(
        _firestore.collection('Appointments').doc(event.appointmentId),
        {
          'status': 'waiting_payment',
          'paymentStatus': 'pending',
          'paymentMethod': paymentMethod,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      add(LoadInvoices(event.patientId));
    } catch (e) {
      emit(
        state.copyWith(
          status: PaymentStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshInvoices(
    RefreshInvoices event,
    Emitter<PaymentState> emit,
  ) async {
    add(LoadInvoices(event.patientId));
  }

  String _normalizePaymentMethod(String method) {
    return 'bank_transfer';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
