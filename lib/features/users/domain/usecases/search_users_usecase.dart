import '../entities/user_profile.dart';
import '../repositories/admin_user_repository.dart';

class SearchUsersUseCase {
  final AdminUserRepository _repository;

  SearchUsersUseCase(this._repository);

  Future<List<UserProfile>> call({
    required String query,
    int page = 0,
    int size = 20,
  }) {
    return _repository.searchUsers(query: query, page: page, size: size);
  }
}
