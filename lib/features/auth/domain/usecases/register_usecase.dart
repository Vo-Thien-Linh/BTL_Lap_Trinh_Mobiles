import '../entities/app_user_entity.dart';
import '../entities/register_request_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUsecase {
  final AuthRepository repository;

  RegisterUsecase({required this.repository});

  Future<AppUserEntity> call(RegisterRequestEntity request) {
    return repository.register(request);
  }
}