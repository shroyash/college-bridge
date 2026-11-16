import '../repositories/admin_user_repository.dart';

class SuspendUserUseCase {
  final AdminUserRepository _repository;

  SuspendUserUseCase(this._repository);

  Future<void> call(int userId) {
    return _repository.suspendUser(userId);
  }
}
