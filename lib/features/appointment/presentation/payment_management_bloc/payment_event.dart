part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class LoadInvoices extends PaymentEvent {
  final String patientId;
  const LoadInvoices(this.patientId);
}

class FilterInvoices extends PaymentEvent {
  final String? status;
  final String? type;
  const FilterInvoices({this.status, this.type});
}

class ProcessPayment extends PaymentEvent {
  final String invoiceId;
  final String appointmentId;
  final String patientId;
  final double amount;
  final String paymentMethod;
  const ProcessPayment({
    required this.invoiceId,
    required this.appointmentId,
    required this.patientId,
    required this.amount,
    required this.paymentMethod,
  });
}

class RefreshInvoices extends PaymentEvent {
  final String patientId;
  const RefreshInvoices(this.patientId);
}

class UpdateInvoicesList extends PaymentEvent {
  final List<InvoiceModel> invoices;
  const UpdateInvoicesList(this.invoices);

  @override
  List<Object?> get props => [invoices];
}
