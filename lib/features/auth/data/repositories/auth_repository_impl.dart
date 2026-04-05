import '../../domain/entities/app_user_entity.dart';
import '../../domain/entities/register_request_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl({required this.remoteDatasource});

  @override
  Future<AppUserEntity> login({
    required String email,
    required String password,
  }) async {
    return remoteDatasource.login(email: email, password: password);
  }

  @override
  Future<AppUserEntity> register(RegisterRequestEntity request) async {
    return remoteDatasource.register(request);
  }

  @override
  Future<void> logout() async {
    await remoteDatasource.logout();
  }
}
