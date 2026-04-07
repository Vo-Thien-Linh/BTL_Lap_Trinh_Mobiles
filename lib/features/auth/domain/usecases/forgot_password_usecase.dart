import '../repositories/auth_repository.dart';

class ForgotPasswordUsecase {
  final AuthRepository repository;

  ForgotPasswordUsecase({required this.repository});

  Future<void> call(String email) {
    return repository.forgotPassword(email);
  }
}