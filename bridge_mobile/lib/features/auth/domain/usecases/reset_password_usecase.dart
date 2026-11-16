import '../repositories/auth_repository.dart';

/// Resets the user's password using the [verificationToken] returned by [VerifyOtpUseCase].
class ResetPasswordUseCase {
  final AuthRepository _repository;

  const ResetPasswordUseCase(this._repository);

  Future<void> call({
    required String email,
    required String verificationToken,
    required String newPassword,
  }) {
    return _repository.resetPassword(
      email: email,
      verificationToken: verificationToken,
      newPassword: newPassword,
    );
  }
}
