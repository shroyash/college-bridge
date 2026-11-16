import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> login({
    required String institutionCode,
    required String email,
    required String password,
  });

  Future<AuthUser> register({
    required String institutionCode,
    required String name,
    required String email,
    required String password,
    required int levelId,
  });

  Future<void> logout({required String refreshToken});

  Future<void> forgotPassword({required String email});

  /// Returns the [verificationToken] to be passed to [resetPassword].
  Future<String> verifyOtp({required String email, required String code});

  Future<void> resetPassword({
    required String email,
    required String verificationToken,
    required String newPassword,
  });
}
