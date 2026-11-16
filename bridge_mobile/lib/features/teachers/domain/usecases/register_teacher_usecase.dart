import 'package:bridge_mobile/features/admin_users/domain/repositories/admin_user_repository.dart';

class RegisterTeacherUseCase {
  final AdminUserRepository _repository;

  RegisterTeacherUseCase(this._repository);

  Future<void> call({
    required String name,
    required String email,
    required String password,
  }) {
    return _repository.registerTeacher(
      name: name,
      email: email,
      password: password,
    );
  }
}
