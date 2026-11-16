import 'package:equatable/equatable.dart';

import '../../../../core/error/auth_exceptions.dart';
import '../../domain/entities/auth_user.dart';

/// Sealed state class for the Auth feature.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no action taken yet.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state — an API call is in flight.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Success state — user is authenticated.
final class AuthSuccess extends AuthState {
  final AuthUser user;
  const AuthSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

/// Typed login failure with distinct reason codes.
/// This lets the UI render a specific message/action per backend reason.
final class AuthLoginFailure extends AuthState {
  final LoginFailureReason reason;
  final String message;
  final String? rejectionReason; // only present for institutionRejected

  const AuthLoginFailure({
    required this.reason,
    required this.message,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [reason, message, rejectionReason];
}

/// Generic failure state — for non-login errors (register, forgot-password, etc.)
final class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
