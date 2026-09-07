import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/student_admin_remote_datasource.dart';

// ── Provider ──────────────────────────────────────────────────────────────

final studentAdminDataSourceProvider =
    Provider<StudentAdminRemoteDataSource>((ref) {
  return StudentAdminRemoteDataSource(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

// ── State ─────────────────────────────────────────────────────────────────

class StudentManagementState {
  final List<StudentSummary> students;
  final StudentFilterOptions? filterOptions;
  final String? selectedFaculty;
  final int? selectedSemester;
  final String? searchQuery;
  final Set<int> selectedStudentIds; // studentId (not userId)
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isTransferring;
  final String? error;
  final String? successMessage;

  const StudentManagementState({
    this.students = const [],
    this.filterOptions,
    this.selectedFaculty,
    this.selectedSemester,
    this.searchQuery,
    this.selectedStudentIds = const {},
    this.currentPage = 0,
    this.totalPages = 0,
    this.totalElements = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isTransferring = false,
    this.error,
    this.successMessage,
  });

  StudentManagementState copyWith({
    List<StudentSummary>? students,
    StudentFilterOptions? filterOptions,
    Object? selectedFaculty = _sentinel,
    Object? selectedSemester = _sentinel,
    Object? searchQuery = _sentinel,
    Set<int>? selectedStudentIds,
    int? currentPage,
    int? totalPages,
    int? totalElements,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isTransferring,
    Object? error = _sentinel,
    Object? successMessage = _sentinel,
  }) {
    return StudentManagementState(
      students: students ?? this.students,
      filterOptions: filterOptions ?? this.filterOptions,
      selectedFaculty: selectedFaculty == _sentinel ? this.selectedFaculty : selectedFaculty as String?,
      selectedSemester: selectedSemester == _sentinel ? this.selectedSemester : selectedSemester as int?,
      searchQuery: searchQuery == _sentinel ? this.searchQuery : searchQuery as String?,
      selectedStudentIds: selectedStudentIds ?? this.selectedStudentIds,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isTransferring: isTransferring ?? this.isTransferring,
      error: error == _sentinel ? this.error : error as String?,
      successMessage: successMessage == _sentinel ? this.successMessage : successMessage as String?,
    );
  }

  bool get hasMore => currentPage < totalPages - 1;
  bool get hasSelection => selectedStudentIds.isNotEmpty;
}

// Sentinel for nullable copyWith
const _sentinel = Object();

// ── Notifier ──────────────────────────────────────────────────────────────

class StudentManagementNotifier extends StateNotifier<StudentManagementState> {
  final StudentAdminRemoteDataSource _ds;

  StudentManagementNotifier(this._ds) : super(const StudentManagementState());

  Future<void> init() async {
    await _loadFilterOptions();
    await _loadStudents(page: 0, refresh: true);
  }

  Future<void> _loadFilterOptions() async {
    try {
      final opts = await _ds.getFilterOptions();
      state = state.copyWith(filterOptions: opts);
    } catch (_) {}
  }

  Future<void> _loadStudents({int page = 0, bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, error: null, currentPage: 0, students: []);
    } else {
      if (state.isLoadingMore || !state.hasMore) return;
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final result = await _ds.getStudents(
        faculty: state.selectedFaculty,
        semester: state.selectedSemester,
        search: state.searchQuery,
        page: page,
      );
      final merged = refresh ? result.students : [...state.students, ...result.students];
      state = state.copyWith(
        students: merged,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalElements: result.totalElements,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() => _loadStudents(page: 0, refresh: true);

  Future<void> loadMore() => _loadStudents(page: state.currentPage + 1);

  void setFacultyFilter(String? faculty) {
    state = state.copyWith(
      selectedFaculty: faculty,
      selectedStudentIds: {},
      currentPage: 0,
    );
    _loadStudents(page: 0, refresh: true);
  }

  void setSemesterFilter(int? semester) {
    state = state.copyWith(
      selectedSemester: semester,
      selectedStudentIds: {},
      currentPage: 0,
    );
    _loadStudents(page: 0, refresh: true);
  }

  void setSearch(String? search) {
    state = state.copyWith(
      searchQuery: search?.isNotEmpty == true ? search : null,
      selectedStudentIds: {},
    );
    _loadStudents(page: 0, refresh: true);
  }

  void toggleStudent(int studentId) {
    final current = Set<int>.from(state.selectedStudentIds);
    if (current.contains(studentId)) {
      current.remove(studentId);
    } else {
      current.add(studentId);
    }
    state = state.copyWith(selectedStudentIds: current);
  }

  void toggleAll() {
    final allIds = state.students
        .map((s) => s.effectiveStudentId)
        .toSet();
    if (state.selectedStudentIds.length == allIds.length) {
      state = state.copyWith(selectedStudentIds: {});
    } else {
      state = state.copyWith(selectedStudentIds: allIds);
    }
  }

  void clearSelection() => state = state.copyWith(selectedStudentIds: {});

  void clearMessages() =>
      state = state.copyWith(error: null, successMessage: null);

  Future<BulkTransferResult?> bulkTransfer(int targetClassId) async {
    final studentIds = state.selectedStudentIds.toList();
    if (studentIds.isEmpty) return null;

    state = state.copyWith(isTransferring: true, error: null);
    try {
      final result = await _ds.bulkTransfer(
        studentIds: studentIds,
        targetClassId: targetClassId,
      );
      state = state.copyWith(
        isTransferring: false,
        selectedStudentIds: {},
        successMessage:
            '${result.updatedStudents} student(s) moved to ${result.targetDisplayName}.',
      );
      await _loadStudents(page: 0, refresh: true);
      return result;
    } catch (e) {
      state = state.copyWith(
        isTransferring: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

final studentManagementProvider =
    StateNotifierProvider<StudentManagementNotifier, StudentManagementState>(
  (ref) => StudentManagementNotifier(ref.watch(studentAdminDataSourceProvider)),
);
