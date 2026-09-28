import '../repositories/admin_user_repository.dart';

class ActivateUserUseCase {
  final AdminUserRepository _repository;

  ActivateUserUseCase(this._repository);

  Future<void> call(int userId) {
    return _repository.activateUser(userId);
  }
}
