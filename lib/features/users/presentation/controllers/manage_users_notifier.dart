import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/activate_user_usecase.dart';
import '../../domain/usecases/filter_users_usecase.dart';
import '../../domain/usecases/search_users_usecase.dart';
import '../../domain/usecases/suspend_user_usecase.dart';
import 'manage_users_state.dart';

class ManageUsersNotifier extends StateNotifier<ManageUsersState> {
  final FilterUsersUseCase _filterUsersUseCase;
  final SearchUsersUseCase _searchUsersUseCase;
  final SuspendUserUseCase _suspendUserUseCase;
  final ActivateUserUseCase _activateUserUseCase;

  String _currentRole = 'TEACHER';
  String _currentStatus = 'ACTIVE';
  String _currentQuery = '';

  ManageUsersNotifier({
    required FilterUsersUseCase filterUsersUseCase,
    required SearchUsersUseCase searchUsersUseCase,
    required SuspendUserUseCase suspendUserUseCase,
    required ActivateUserUseCase activateUserUseCase,
  })  : _filterUsersUseCase = filterUsersUseCase,
        _searchUsersUseCase = searchUsersUseCase,
        _suspendUserUseCase = suspendUserUseCase,
        _activateUserUseCase = activateUserUseCase,
        super(const ManageUsersInitial());

  String get currentRole => _currentRole;
  String get currentStatus => _currentStatus;
  String get currentQuery => _currentQuery;

  Future<void> fetchUsers({String? role, String? status}) async {
    if (role != null) _currentRole = role;
    if (status != null) _currentStatus = status;

    state = const ManageUsersLoading();
    try {
      final List<UserProfile> users;
      if (_currentQuery.trim().isNotEmpty) {
        users = await _searchUsersUseCase(query: _currentQuery.trim());
      } else {
        users = await _filterUsersUseCase(
          role: _currentRole,
          status: _currentStatus,
        );
      }
      state = ManageUsersSuccess(
        users: users,
        activeRole: _currentRole,
        activeStatus: _currentStatus,
        searchQuery: _currentQuery,
      );
    } catch (e) {
      state = ManageUsersFailure(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> selectRoleTab(String role) async {
    if (_currentRole == role) return;
    _currentRole = role;
    await fetchUsers();
  }

  Future<void> selectStatusTab(String status) async {
    if (_currentStatus == status) return;
    _currentStatus = status;
    await fetchUsers();
  }

  Future<void> search(String query) async {
    _currentQuery = query;
    await fetchUsers();
  }

  Future<bool> suspendUser(int userId) async {
    try {
      await _suspendUserUseCase(userId);
      await fetchUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> activateUser(int userId) async {
    try {
      await _activateUserUseCase(userId);
      await fetchUsers();
      return true;
    } catch (e) {
      return false;
    }
  }
}
