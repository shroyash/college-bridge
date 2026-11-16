import 'package:equatable/equatable.dart';
import '../../data/models/institution_model.dart';

/// Core domain entity representing an authenticated user.
class AuthUser extends Equatable {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String name;
  final String email;
  final String role;
  final InstitutionModel? institution;

  const AuthUser({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.institution,
  });

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        userId,
        name,
        email,
        role,
        institution,
      ];
}
