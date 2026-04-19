part of 'payment_bloc.dart';

enum PaymentStatus { initial, loading, success, failure, processing }

class PaymentState extends Equatable {
  final PaymentStatus status;
  final List<InvoiceModel> allInvoices;
  final List<InvoiceModel> filteredInvoices;
  final String? errorMessage;
  final String? selectedStatus;
  final String? selectedType;

  const PaymentState({
    this.status = PaymentStatus.initial,
    this.allInvoices = const [],
    this.filteredInvoices = const [],
    this.errorMessage,
    this.selectedStatus,
    this.selectedType,
  });

  PaymentState copyWith({
    PaymentStatus? status,
    List<InvoiceModel>? allInvoices,
    List<InvoiceModel>? filteredInvoices,
    String? errorMessage,
    String? selectedStatus,
    String? selectedType,
  }) {
    return PaymentState(
      status: status ?? this.status,
      allInvoices: allInvoices ?? this.allInvoices,
      filteredInvoices: filteredInvoices ?? this.filteredInvoices,
      errorMessage: errorMessage,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedType: selectedType ?? this.selectedType,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allInvoices,
        filteredInvoices,
        errorMessage,
        selectedStatus,
        selectedType,
      ];
}
