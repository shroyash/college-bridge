import '../entities/user_profile.dart';
import '../repositories/admin_user_repository.dart';

class FilterUsersUseCase {
  final AdminUserRepository _repository;

  FilterUsersUseCase(this._repository);

  Future<List<UserProfile>> call({
    required String role,
    required String status,
    int page = 0,
    int size = 20,
  }) {
    return _repository.filterUsers(
      role: role,
      status: status,
      page: page,
      size: size,
    );
  }
}
