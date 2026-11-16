import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Single responsibility use-case: log in an existing user.
class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  Future<AuthUser> call({
    required String institutionCode,
    required String email,
    required String password,
  }) {
    return _repository.login(
      institutionCode: institutionCode,
      email: email,
      password: password,
    );
  }
}
