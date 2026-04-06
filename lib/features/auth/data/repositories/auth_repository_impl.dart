import '../../domain/entities/app_user_entity.dart';
import '../../domain/entities/register_request_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl({required this.remoteDatasource});

  @override
  Future<AppUserEntity> register(RegisterRequestEntity request) async {
    final userModel = await remoteDatasource.register(request);
    return userModel.toEntity();
  }

  @override
  Future<AppUserEntity> login({
    required String email,
    required String password,
  }) async {
    final userModel = await remoteDatasource.login(
      email: email,
      password: password,
    );
    return userModel.toEntity();
  }

  @override
  Future<void> logout() {
    return remoteDatasource.logout();
  }

  @override
  Future<void> forgotPassword(String email) {
    return remoteDatasource.forgotPassword(email);
  }

  @override
  Future<AppUserEntity?> getCurrentUser() async {
    final userModel = await remoteDatasource.getCurrentUser();
    return userModel?.toEntity();
  }
}