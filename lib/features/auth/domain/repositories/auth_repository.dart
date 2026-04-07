import '../entities/app_user_entity.dart';
import '../entities/register_request_entity.dart';

abstract class AuthRepository {
  Future<AppUserEntity> register(RegisterRequestEntity request);
  Future<AppUserEntity> login({
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<AppUserEntity?> getCurrentUser();
}