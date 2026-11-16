import '../repositories/auth_repository.dart';

/// Single responsibility use-case: send OTP to the provided email.
class ForgotPasswordUseCase {
  final AuthRepository _repository;

  const ForgotPasswordUseCase(this._repository);

  Future<void> call({required String email}) {
    return _repository.forgotPassword(email: email);
  }
}
