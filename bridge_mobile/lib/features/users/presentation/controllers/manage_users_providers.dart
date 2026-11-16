import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/admin_user_remote_datasource.dart';
import '../../data/repositories/admin_user_repository_impl.dart';
import '../../domain/repositories/admin_user_repository.dart';
import '../../domain/usecases/activate_user_usecase.dart';
import '../../domain/usecases/filter_users_usecase.dart';
import 'package:bridge_mobile/features/students/domain/usecases/get_student_subjects_usecase.dart';
import 'package:bridge_mobile/features/subjects/domain/usecases/manage_teacher_assignments_usecase.dart';
import 'package:bridge_mobile/features/teachers/domain/usecases/register_teacher_usecase.dart';
import '../../domain/usecases/search_users_usecase.dart';
import '../../domain/usecases/suspend_user_usecase.dart';
import 'package:bridge_mobile/features/subjects/presentation/controllers/assign_classes_notifier.dart';
import 'manage_users_notifier.dart';
import 'manage_users_state.dart';


final adminUserRemoteDataSourceProvider =
    Provider<AdminUserRemoteDataSource>((ref) {
  return AdminUserRemoteDataSource(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

final adminUserRepositoryProvider = Provider<AdminUserRepository>((ref) {
  return AdminUserRepositoryImpl(ref.watch(adminUserRemoteDataSourceProvider));
});

// Use cases
final filterUsersUseCaseProvider = Provider<FilterUsersUseCase>((ref) {
  return FilterUsersUseCase(ref.watch(adminUserRepositoryProvider));
});

final searchUsersUseCaseProvider = Provider<SearchUsersUseCase>((ref) {
  return SearchUsersUseCase(ref.watch(adminUserRepositoryProvider));
});

final suspendUserUseCaseProvider = Provider<SuspendUserUseCase>((ref) {
  return SuspendUserUseCase(ref.watch(adminUserRepositoryProvider));
});

final activateUserUseCaseProvider = Provider<ActivateUserUseCase>((ref) {
  return ActivateUserUseCase(ref.watch(adminUserRepositoryProvider));
});

final registerTeacherUseCaseProvider = Provider<RegisterTeacherUseCase>((ref) {
  return RegisterTeacherUseCase(ref.watch(adminUserRepositoryProvider));
});

final manageTeacherAssignmentsUseCaseProvider =
    Provider<ManageTeacherAssignmentsUseCase>((ref) {
  return ManageTeacherAssignmentsUseCase(
      ref.watch(adminUserRepositoryProvider));
});

final getStudentSubjectsUseCaseProvider = Provider<GetStudentSubjectsUseCase>((ref) {
  return GetStudentSubjectsUseCase(ref.watch(adminUserRepositoryProvider));
});

// Notifiers
final manageUsersNotifierProvider = StateNotifierProvider<
    ManageUsersNotifier, ManageUsersState>((ref) {
  return ManageUsersNotifier(
    filterUsersUseCase: ref.watch(filterUsersUseCaseProvider),
    searchUsersUseCase: ref.watch(searchUsersUseCaseProvider),
    suspendUserUseCase: ref.watch(suspendUserUseCaseProvider),
    activateUserUseCase: ref.watch(activateUserUseCaseProvider),
  );
});

final assignClassesNotifierProvider = StateNotifierProvider.family<
    AssignClassesNotifier, AssignClassesState, int>((ref, teacherId) {
  return AssignClassesNotifier(
    useCase: ref.watch(manageTeacherAssignmentsUseCaseProvider),
    teacherId: teacherId,
  );
});
