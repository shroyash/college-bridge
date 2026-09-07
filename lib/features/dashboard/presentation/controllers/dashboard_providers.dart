import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/dashboard_metric.dart';
import '../../domain/entities/subject.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_admin_dashboard_usecase.dart';
import '../../domain/usecases/get_my_subjects_usecase.dart';
import '../../../admin_users/domain/entities/teacher_assignment.dart';
import '../../../admin_users/presentation/controllers/manage_users_providers.dart';
import 'admin_dashboard_notifier.dart';
import 'dashboard_state.dart';
import 'profile_notifier.dart';
import 'student_dashboard_notifier.dart';
import 'teacher_dashboard_notifier.dart';

// ── Data Layer ─────────────────────────────────────────────────────────────
// NOTE: apiClientProvider is the singleton defined in core/network/api_client.dart.
// Do NOT declare a private copy — all features must share the same Dio instance
// so the AuthInterceptor (token attach + refresh) applies everywhere.

final dashboardRemoteDataSourceProvider =
    Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

// ── Domain — Use Cases ──────────────────────────────────────────────────────

final getAdminDashboardUseCaseProvider =
    Provider<GetAdminDashboardUseCase>((ref) {
  return GetAdminDashboardUseCase(ref.watch(dashboardRepositoryProvider));
});

final getMySubjectsUseCaseProvider = Provider<GetMySubjectsUseCase>((ref) {
  return GetMySubjectsUseCase(ref.watch(dashboardRepositoryProvider));
});

// ── Presentation — Notifier ─────────────────────────────────────────────────

final adminDashboardNotifierProvider = StateNotifierProvider<
    AdminDashboardNotifier, DashboardState<List<DashboardMetric>>>((ref) {
  return AdminDashboardNotifier(ref.watch(getAdminDashboardUseCaseProvider));
});

final studentDashboardNotifierProvider = StateNotifierProvider<
    StudentDashboardNotifier, DashboardState<List<Subject>>>((ref) {
  return StudentDashboardNotifier(ref.watch(getMySubjectsUseCaseProvider));
});

final teacherDashboardNotifierProvider = StateNotifierProvider<
    TeacherDashboardNotifier, DashboardState<List<TeacherAssignment>>>((ref) {
  return TeacherDashboardNotifier(
    ref.watch(manageTeacherAssignmentsUseCaseProvider),
    ref.watch(getMySubjectsUseCaseProvider),
  );
});

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(
    ref.watch(manageTeacherAssignmentsUseCaseProvider),
    ref.watch(secureStorageProvider),
  );
});
