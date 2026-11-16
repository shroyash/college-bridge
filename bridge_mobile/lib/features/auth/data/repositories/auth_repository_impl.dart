import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Concrete implementation of [AuthRepository].
/// Bridges the remote datasource to the domain layer.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  const AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<AuthUser> login({
    required String institutionCode,
    required String email,
    required String password,
  }) async {
    final model = await _remoteDataSource.login(
      institutionCode: institutionCode,
      email: email,
      password: password,
    );
    return model;
  }

  @override
  Future<AuthUser> register({
    required String institutionCode,
    required String name,
    required String email,
    required String password,
    required int levelId,
  }) async {
    final model = await _remoteDataSource.register(
      institutionCode: institutionCode,
      name: name,
      email: email,
      password: password,
      levelId: levelId,
    );
    return model;
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await _remoteDataSource.logout(refreshToken: refreshToken);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<String> verifyOtp({required String email, required String code}) async {
    return _remoteDataSource.verifyOtp(email: email, code: code);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String verificationToken,
    required String newPassword,
  }) async {
    await _remoteDataSource.resetPassword(
      email: email,
      verificationToken: verificationToken,
      newPassword: newPassword,
    );
  }
}
