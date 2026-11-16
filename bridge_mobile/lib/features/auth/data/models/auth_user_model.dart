import '../../domain/entities/auth_user.dart';
import 'institution_model.dart';

/// Data Transfer Object — maps the backend AuthResponse:
/// { accessToken, refreshToken, user: { userId, name, email, role, institution: { institutionId, name, code } } }
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.accessToken,
    required super.refreshToken,
    required super.userId,
    required super.name,
    required super.email,
    required super.role,
    super.institution,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    // Handle optional 'data' wrapper if full ApiResponse object is passed directly
    final rootRaw = (json.containsKey('data') && json['data'] is Map)
        ? json['data']
        : json;
    final Map<String, dynamic> root = rootRaw is Map
        ? Map<String, dynamic>.from(rootRaw)
        : json;

    final accessToken = (root['accessToken'] ?? root['token'] ?? json['accessToken'])?.toString() ?? '';
    final refreshToken = (root['refreshToken'] ?? json['refreshToken'])?.toString() ?? '';

    final userRaw = root['user'] ?? json['user'];
    final Map<String, dynamic> userJson = userRaw is Map
        ? Map<String, dynamic>.from(userRaw)
        : root;

    final instRaw = userJson['institution'] ?? root['institution'];
    final Map<String, dynamic>? instJson = instRaw is Map
        ? Map<String, dynamic>.from(instRaw)
        : null;

    final rawUserId = userJson['userId'] ?? userJson['id'] ?? root['userId'];
    final userId = rawUserId is num
        ? rawUserId.toInt()
        : (int.tryParse(rawUserId?.toString() ?? '') ?? 0);

    final name = (userJson['name'] ?? root['name'])?.toString() ?? '';
    final email = (userJson['email'] ?? root['email'])?.toString() ?? '';
    final role = (userJson['role'] ?? root['role'])?.toString() ?? '';

    return AuthUserModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      name: name,
      email: email,
      role: role,
      institution: instJson != null ? InstitutionModel.fromJson(instJson) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'user': {
          'userId': userId,
          'name': name,
          'email': email,
          'role': role,
          'institution': institution?.toJson(),
        },
      };
}
