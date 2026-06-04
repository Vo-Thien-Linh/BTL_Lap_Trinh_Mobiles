import '../../data/models/payment_model.dart';

abstract class PatientPaymentRepository {
  Stream<List<PatientPaymentModel>> watchPatientPayments(String patientId);

  Stream<PatientPaymentModel?> watchPaymentByPath(String sourcePath);

  Future<String> createPayosCheckoutLink({
    required PatientPaymentModel payment,
    required String patientId,
  });

  Future<void> markPayAtCounter(PatientPaymentModel payment);
}
