import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'forgot_password_state.dart';

/// Orchestrates the three-step forgot-password flow:
///   1. sendOtp      → ForgotPasswordOtpSent
///   2. verifyOtp    → ForgotPasswordOtpVerified
///   3. resetPassword→ ForgotPasswordResetSuccess
class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  ForgotPasswordNotifier({
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
  })  : _forgotPasswordUseCase = forgotPasswordUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        super(const ForgotPasswordInitial());

  /// Step 1: Send OTP to email.
  Future<void> sendOtp({required String email}) async {
    state = const ForgotPasswordLoading();
    try {
      await _forgotPasswordUseCase(email: email);
      state = ForgotPasswordOtpSent(email);
    } catch (e) {
      state = ForgotPasswordFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Step 2: Verify the 6-digit OTP code. Receives verificationToken from backend.
  Future<void> verifyOtp({required String email, required String code}) async {
    state = const ForgotPasswordLoading();
    try {
      final verificationToken = await _verifyOtpUseCase(email: email, code: code);
      state = ForgotPasswordOtpVerified(
        email: email,
        verificationToken: verificationToken,
      );
    } catch (e) {
      state = ForgotPasswordFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Step 3: Reset password using the verificationToken.
  Future<void> resetPassword({
    required String email,
    required String verificationToken,
    required String newPassword,
  }) async {
    state = const ForgotPasswordLoading();
    try {
      await _resetPasswordUseCase(
        email: email,
        verificationToken: verificationToken,
        newPassword: newPassword,
      );
      state = const ForgotPasswordResetSuccess();
    } catch (e) {
      state = ForgotPasswordFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void reset() => state = const ForgotPasswordInitial();
}
