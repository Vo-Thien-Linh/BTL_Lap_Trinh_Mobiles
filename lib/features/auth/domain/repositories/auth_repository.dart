import '../entities/app_user_entity.dart';
import '../entities/register_request_entity.dart';

abstract class AuthRepository {
  Future<AppUserEntity> login({
    required String email,
    required String password,
  });
  Future<AppUserEntity> register(RegisterRequestEntity request);
  Future<void> logout();
}
