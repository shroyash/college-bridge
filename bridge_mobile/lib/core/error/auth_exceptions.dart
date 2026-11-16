/// Typed login failure reasons that map to distinct backend error codes.
/// The backend returns these as `errorCode` or embedded in the message
/// on a 403 response.
enum LoginFailureReason {
  institutionPending,
  institutionRejected,
  institutionSuspended,
  userSuspended,
  userInactive,
  invalidCredentials,
  unknown,
}

/// Thrown by the auth data source when login fails with a known reason.
class LoginFailureException implements Exception {
  final LoginFailureReason reason;
  final String message;
  final String? rejectionReason; // Only present for institutionRejected

  const LoginFailureException({
    required this.reason,
    required this.message,
    this.rejectionReason,
  });

  @override
  String toString() => 'LoginFailureException($reason): $message';
}
