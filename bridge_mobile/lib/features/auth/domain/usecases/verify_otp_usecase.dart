import '../repositories/auth_repository.dart';

/// Verifies the 6-digit OTP code with the backend.
/// Returns a [verificationToken] that must be passed to [ResetPasswordUseCase].
class VerifyOtpUseCase {
  final AuthRepository _repository;

  const VerifyOtpUseCase(this._repository);

  Future<String> call({required String email, required String code}) {
    return _repository.verifyOtp(email: email, code: code);
  }
}
