import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/super_admin_remote_datasource.dart';
import '../../domain/entities/super_admin_models.dart';

final superAdminRemoteDataSourceProvider =
    Provider<SuperAdminRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return SuperAdminRemoteDataSource(apiClient, storage);
});

// ── Dashboard Controller ─────────────────────────────────────────────────────

class SuperAdminDashboardState {
  final bool isLoading;
  final String? error;
  final SuperAdminDashboardStats? stats;
  final List<SuperAdminPendingInstitution> pendingQueue;

  const SuperAdminDashboardState({
    this.isLoading = false,
    this.error,
    this.stats,
    this.pendingQueue = const [],
  });

  SuperAdminDashboardState copyWith({
    bool? isLoading,
    String? error,
    SuperAdminDashboardStats? stats,
    List<SuperAdminPendingInstitution>? pendingQueue,
  }) {
    return SuperAdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
      pendingQueue: pendingQueue ?? this.pendingQueue,
    );
  }
}

class SuperAdminDashboardNotifier
    extends StateNotifier<SuperAdminDashboardState> {
  final SuperAdminRemoteDataSource _dataSource;

  SuperAdminDashboardNotifier(this._dataSource)
      : super(const SuperAdminDashboardState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statsFuture = _dataSource.getDashboardStats();
      final pendingFuture = _dataSource.getPendingInstitutions();

      final stats = await statsFuture;
      final pendingList = await pendingFuture;

      state = state.copyWith(
        isLoading: false,
        stats: stats,
        pendingQueue: pendingList,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final superAdminDashboardProvider = StateNotifierProvider<
    SuperAdminDashboardNotifier, SuperAdminDashboardState>((ref) {
  final ds = ref.watch(superAdminRemoteDataSourceProvider);
  return SuperAdminDashboardNotifier(ds);
});

// ── Users Controller ─────────────────────────────────────────────────────────

class SuperAdminUsersState {
  final bool isLoading;
  final bool isMoreLoading;
  final String? error;
  final String search;
  final String roleFilter;
  final String statusFilter;
  final List<SuperAdminUser> users;
  final int page;
  final int totalPages;
  final int totalElements;
  final bool hasNext;
  final int totalUsersCount;
  final int studentsCount;
  final int teachersCount;
  final int adminsCount;

  const SuperAdminUsersState({
    this.isLoading = false,
    this.isMoreLoading = false,
    this.error,
    this.search = '',
    this.roleFilter = 'ALL',
    this.statusFilter = 'ALL',
    this.users = const [],
    this.page = 0,
    this.totalPages = 0,
    this.totalElements = 0,
    this.hasNext = false,
    this.totalUsersCount = 0,
    this.studentsCount = 0,
    this.teachersCount = 0,
    this.adminsCount = 0,
  });

  SuperAdminUsersState copyWith({
    bool? isLoading,
    bool? isMoreLoading,
    String? error,
    String? search,
    String? roleFilter,
    String? statusFilter,
    List<SuperAdminUser>? users,
    int? page,
    int? totalPages,
    int? totalElements,
    bool? hasNext,
    int? totalUsersCount,
    int? studentsCount,
    int? teachersCount,
    int? adminsCount,
  }) {
    return SuperAdminUsersState(
      isLoading: isLoading ?? this.isLoading,
      isMoreLoading: isMoreLoading ?? this.isMoreLoading,
      error: error,
      search: search ?? this.search,
      roleFilter: roleFilter ?? this.roleFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      users: users ?? this.users,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      hasNext: hasNext ?? this.hasNext,
      totalUsersCount: totalUsersCount ?? this.totalUsersCount,
      studentsCount: studentsCount ?? this.studentsCount,
      teachersCount: teachersCount ?? this.teachersCount,
      adminsCount: adminsCount ?? this.adminsCount,
    );
  }
}

class SuperAdminUsersNotifier extends StateNotifier<SuperAdminUsersState> {
  final SuperAdminRemoteDataSource _dataSource;

  SuperAdminUsersNotifier(this._dataSource)
      : super(const SuperAdminUsersState());

  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 0);
    }
    state = state.copyWith(isLoading: true, error: null);

    try {
      final stats = await _dataSource.getDashboardStats();

      final PaginatedResponse<SuperAdminUser> response;
      if (state.roleFilter == 'ADMIN') {
        response = await _dataSource.getAdmins(
          page: 0,
          size: 20,
          search: state.search,
          status: state.statusFilter,
        );
      } else {
        response = await _dataSource.getUsers(
          page: 0,
          size: 20,
          search: state.search,
          role: state.roleFilter,
          status: state.statusFilter,
        );
      }

      state = state.copyWith(
        isLoading: false,
        users: response.content,
        page: response.currentPage,
        totalPages: response.totalPages,
        totalElements: response.totalElements,
        hasNext: response.hasNext,
        totalUsersCount: stats.totalUsers,
        studentsCount: stats.totalStudents,
        teachersCount: stats.totalTeachers,
        adminsCount: stats.totalAdmins,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasNext || state.isMoreLoading || state.isLoading) return;
    state = state.copyWith(isMoreLoading: true);

    try {
      final nextPage = state.page + 1;
      final PaginatedResponse<SuperAdminUser> response;
      if (state.roleFilter == 'ADMIN') {
        response = await _dataSource.getAdmins(
          page: nextPage,
          size: 20,
          search: state.search,
          status: state.statusFilter,
        );
      } else {
        response = await _dataSource.getUsers(
          page: nextPage,
          size: 20,
          search: state.search,
          role: state.roleFilter,
          status: state.statusFilter,
        );
      }

      state = state.copyWith(
        isMoreLoading: false,
        users: [...state.users, ...response.content],
        page: response.currentPage,
        totalPages: response.totalPages,
        totalElements: response.totalElements,
        hasNext: response.hasNext,
      );
    } catch (e) {
      state = state.copyWith(isMoreLoading: false);
    }
  }

  void setSearch(String query) {
    state = state.copyWith(search: query);
    loadUsers(refresh: true);
  }

  void setFilter({String? role, String? status}) {
    state = state.copyWith(
      roleFilter: role ?? state.roleFilter,
      statusFilter: status ?? state.statusFilter,
    );
    loadUsers(refresh: true);
  }

  Future<void> suspendUser(int userId) async {
    try {
      await _dataSource.suspendUser(userId);
      await loadUsers(refresh: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> activateUser(int userId) async {
    try {
      await _dataSource.activateUser(userId);
      await loadUsers(refresh: true);
    } catch (e) {
      rethrow;
    }
  }
}

final superAdminUsersProvider =
    StateNotifierProvider<SuperAdminUsersNotifier, SuperAdminUsersState>((ref) {
  final ds = ref.watch(superAdminRemoteDataSourceProvider);
  return SuperAdminUsersNotifier(ds);
});

// ── Institutions Controller ──────────────────────────────────────────────────

class SuperAdminInstitutionsState {
  final int currentTab; // 0: All, 1: Pending
  final bool isLoading;
  final bool isMoreLoading;
  final String? error;
  final String search;
  final String statusFilter;
  final List<SuperAdminInstitution> allInstitutions;
  final int allPage;
  final int allTotalPages;
  final bool allHasNext;
  final List<SuperAdminPendingInstitution> pendingInstitutions;
  final int pendingPage;
  final int pendingTotalPages;
  final bool pendingHasNext;
  final int pendingTotalCount;

  const SuperAdminInstitutionsState({
    this.currentTab = 0,
    this.isLoading = false,
    this.isMoreLoading = false,
    this.error,
    this.search = '',
    this.statusFilter = 'ALL',
    this.allInstitutions = const [],
    this.allPage = 0,
    this.allTotalPages = 0,
    this.allHasNext = false,
    this.pendingInstitutions = const [],
    this.pendingPage = 0,
    this.pendingTotalPages = 0,
    this.pendingHasNext = false,
    this.pendingTotalCount = 0,
  });

  SuperAdminInstitutionsState copyWith({
    int? currentTab,
    bool? isLoading,
    bool? isMoreLoading,
    String? error,
    String? search,
    String? statusFilter,
    List<SuperAdminInstitution>? allInstitutions,
    int? allPage,
    int? allTotalPages,
    bool? allHasNext,
    List<SuperAdminPendingInstitution>? pendingInstitutions,
    int? pendingPage,
    int? pendingTotalPages,
    bool? pendingHasNext,
    int? pendingTotalCount,
  }) {
    return SuperAdminInstitutionsState(
      currentTab: currentTab ?? this.currentTab,
      isLoading: isLoading ?? this.isLoading,
      isMoreLoading: isMoreLoading ?? this.isMoreLoading,
      error: error,
      search: search ?? this.search,
      statusFilter: statusFilter ?? this.statusFilter,
      allInstitutions: allInstitutions ?? this.allInstitutions,
      allPage: allPage ?? this.allPage,
      allTotalPages: allTotalPages ?? this.allTotalPages,
      allHasNext: allHasNext ?? this.allHasNext,
      pendingInstitutions: pendingInstitutions ?? this.pendingInstitutions,
      pendingPage: pendingPage ?? this.pendingPage,
      pendingTotalPages: pendingTotalPages ?? this.pendingTotalPages,
      pendingHasNext: pendingHasNext ?? this.pendingHasNext,
      pendingTotalCount: pendingTotalCount ?? this.pendingTotalCount,
    );
  }
}

class SuperAdminInstitutionsNotifier
    extends StateNotifier<SuperAdminInstitutionsState> {
  final SuperAdminRemoteDataSource _dataSource;

  SuperAdminInstitutionsNotifier(this._dataSource)
      : super(const SuperAdminInstitutionsState());

  void setTab(int tab) {
    state = state.copyWith(currentTab: tab);
    loadData(refresh: true);
  }

  void setSearch(String query) {
    state = state.copyWith(search: query);
    loadData(refresh: true);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
    loadData(refresh: true);
  }

  Future<void> loadData({bool refresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Always fetch pending count badge
      final pendingList = await _dataSource.getPendingInstitutions(
        search: state.currentTab == 1 ? state.search : null,
      );

      if (state.currentTab == 0) {
        final allRes = await _dataSource.getInstitutions(
          page: 0,
          size: 20,
          search: state.search,
          status: state.statusFilter,
        );

        state = state.copyWith(
          isLoading: false,
          allInstitutions: allRes.content,
          allPage: allRes.currentPage,
          allTotalPages: allRes.totalPages,
          allHasNext: allRes.hasNext,
          pendingTotalCount: pendingList.length,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          pendingInstitutions: pendingList,
          pendingPage: 0,
          pendingTotalPages: 1,
          pendingHasNext: false,
          pendingTotalCount: pendingList.length,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> approveInstitution(int id) async {
    try {
      await _dataSource.approveInstitution(id);
      loadData(refresh: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectInstitution(int id, String reason) async {
    try {
      await _dataSource.rejectInstitution(id, reason);
      loadData(refresh: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> suspendInstitution(int id) async {
    try {
      await _dataSource.suspendInstitution(id);
      loadData(refresh: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reactivateInstitution(int id) async {
    try {
      await _dataSource.reactivateInstitution(id);
      loadData(refresh: true);
    } catch (e) {
      rethrow;
    }
  }
}

final superAdminInstitutionsProvider = StateNotifierProvider<
    SuperAdminInstitutionsNotifier, SuperAdminInstitutionsState>((ref) {
  final ds = ref.watch(superAdminRemoteDataSourceProvider);
  return SuperAdminInstitutionsNotifier(ds);
});
