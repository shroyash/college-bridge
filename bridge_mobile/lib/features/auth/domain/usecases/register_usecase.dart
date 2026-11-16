import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Single responsibility use-case: register a new student account.
class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<AuthUser> call({
    required String institutionCode,
    required String name,
    required String email,
    required String password,
    required int levelId,
  }) {
    return _repository.register(
      institutionCode: institutionCode,
      name: name,
      email: email,
      password: password,
      levelId: levelId,
    );
  }
}
