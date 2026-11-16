import 'package:equatable/equatable.dart';

/// Sealed state for the forgot-password / OTP / reset-password flow.
sealed class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

/// No action taken yet.
final class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

/// An API call is in flight.
final class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

/// OTP was sent successfully — move to OTP screen.
final class ForgotPasswordOtpSent extends ForgotPasswordState {
  final String email;
  const ForgotPasswordOtpSent(this.email);

  @override
  List<Object?> get props => [email];
}

/// OTP was verified — move to new-password screen.
/// Carries the [verificationToken] returned by the backend.
final class ForgotPasswordOtpVerified extends ForgotPasswordState {
  final String email;
  final String verificationToken;
  const ForgotPasswordOtpVerified({
    required this.email,
    required this.verificationToken,
  });

  @override
  List<Object?> get props => [email, verificationToken];
}

/// Password was reset successfully.
final class ForgotPasswordResetSuccess extends ForgotPasswordState {
  const ForgotPasswordResetSuccess();
}

/// An error occurred at any step.
final class ForgotPasswordFailure extends ForgotPasswordState {
  final String message;
  const ForgotPasswordFailure(this.message);

  @override
  List<Object?> get props => [message];
}
