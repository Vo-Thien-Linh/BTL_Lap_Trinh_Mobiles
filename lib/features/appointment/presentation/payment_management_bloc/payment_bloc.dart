import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/invoice_models.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _invoiceSubscription;

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
    return super.close();
  }

  Future<void> _onLoadInvoices(
    LoadInvoices event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(status: PaymentStatus.loading));
    
    // Cancel existing subscription if any
    await _invoiceSubscription?.cancel();

    // 1. Subscribe to real-time stream
    _invoiceSubscription = _firestore
        .collection('Invoices')
        .where('patientId', isEqualTo: event.patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          final List<InvoiceModel> invoices = snapshot.docs
              .map((doc) => InvoiceModel.fromFirestore(doc))
              .toList();
          
          add(UpdateInvoicesList(invoices));
        });

  }

  void _onUpdateInvoicesList(
    UpdateInvoicesList event,
    Emitter<PaymentState> emit,
  ) {
    emit(state.copyWith(
      status: PaymentStatus.success,
      allInvoices: event.invoices,
      filteredInvoices: _applyFilters(event.invoices, state.selectedStatus, state.selectedType),
    ));
  }

  List<InvoiceModel> _applyFilters(List<InvoiceModel> all, String? status, String? type) {
    final currentStatus = status ?? 'Tất cả trạng thái';
    final currentType = type ?? 'Tất cả loại';
    
    List<InvoiceModel> filtered = all;

    if (currentStatus != 'Tất cả trạng thái') {
      final statusMap = {'Đã thanh toán': 'paid', 'Chưa thanh toán': 'unpaid'};
      filtered = filtered.where((i) => i.status == statusMap[currentStatus]).toList();
    }

    if (currentType != 'Tất cả loại') {
      filtered = filtered.where((i) => i.expenseType == currentType).toList();
    }
    
    return filtered;
  }

  void _onFilterInvoices(
    FilterInvoices event,
    Emitter<PaymentState> emit,
  ) {
    final status = event.status ?? state.selectedStatus ?? 'Tất cả trạng thái';
    final type = event.type ?? state.selectedType ?? 'Tất cả loại';

    List<InvoiceModel> filtered = state.allInvoices;

    if (status != 'Tất cả trạng thái') {
      final statusMap = {'Đã thanh toán': 'paid', 'Chưa thanh toán': 'unpaid'};
      filtered = filtered.where((i) => i.status == statusMap[status]).toList();
    }

    if (type != 'Tất cả loại') {
      filtered = filtered.where((i) => i.expenseType == type).toList();
    }

    emit(state.copyWith(
      filteredInvoices: filtered,
      selectedStatus: status,
      selectedType: type,
    ));
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(status: PaymentStatus.processing));
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // 1. Update Invoice
      batch.update(_firestore.collection('Invoices').doc(event.invoiceId), {
        'status': 'paid',
        'paymentDate': Timestamp.fromDate(now),
      });

      // 2. Update Payment record
      final paymentSnapshot = await _firestore
          .collection('Payments')
          .where('invoiceId', isEqualTo: event.invoiceId)
          .limit(1)
          .get();

      if (paymentSnapshot.docs.isNotEmpty) {
        batch.update(paymentSnapshot.docs.first.reference, {
          'status': 'paid',
          'method': event.paymentMethod,
          'paymentDate': Timestamp.fromDate(now),
          'transactionId': 'TXN${now.millisecondsSinceEpoch}',
        });
      }

      // 3. Update Appointment
      batch.update(_firestore.collection('Appointments').doc(event.appointmentId), {
        'status': 'confirmed',
        'paymentStatus': 'paid',
      });

      await batch.commit();

      // Reload invoices
      add(LoadInvoices(event.patientId));
    } catch (e) {
      emit(state.copyWith(
        status: PaymentStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshInvoices(
    RefreshInvoices event,
    Emitter<PaymentState> emit,
  ) async {
    add(LoadInvoices(event.patientId));
  }

}
