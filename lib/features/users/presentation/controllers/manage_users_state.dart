import '../../domain/entities/user_profile.dart';

abstract class ManageUsersState {
  const ManageUsersState();
}

class ManageUsersInitial extends ManageUsersState {
  const ManageUsersInitial();
}

class ManageUsersLoading extends ManageUsersState {
  const ManageUsersLoading();
}

class ManageUsersSuccess extends ManageUsersState {
  final List<UserProfile> users;
  final String activeRole; // 'TEACHER' or 'STUDENT'
  final String activeStatus; // 'ACTIVE', 'SUSPENDED', 'PENDING'
  final String searchQuery;

  const ManageUsersSuccess({
    required this.users,
    required this.activeRole,
    required this.activeStatus,
    this.searchQuery = '',
  });

  ManageUsersSuccess copyWith({
    List<UserProfile>? users,
    String? activeRole,
    String? activeStatus,
    String? searchQuery,
  }) {
    return ManageUsersSuccess(
      users: users ?? this.users,
      activeRole: activeRole ?? this.activeRole,
      activeStatus: activeStatus ?? this.activeStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ManageUsersFailure extends ManageUsersState {
  final String message;

  const ManageUsersFailure(this.message);
}
