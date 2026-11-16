import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bridge_mobile/core/network/api_client.dart';
import 'package:bridge_mobile/core/storage/secure_storage_service.dart';
import 'package:bridge_mobile/features/institution_admin/data/datasources/academic_admin_remote_datasource.dart';
import 'package:bridge_mobile/features/institution_admin/data/datasources/student_academic_remote_datasource.dart';
import 'package:bridge_mobile/features/institution_admin/data/datasources/teacher_academic_remote_datasource.dart';
import 'package:bridge_mobile/features/institution_admin/data/models/academic_class_model.dart';
import 'package:bridge_mobile/features/institution_admin/data/models/class_detail_model.dart';


final teacherAcademicRemoteDataSourceProvider =
    Provider<TeacherAcademicRemoteDataSource>((ref) {
  return TeacherAcademicRemoteDataSource(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

final studentAcademicRemoteDataSourceProvider =
    Provider<StudentAcademicRemoteDataSource>((ref) {
  return StudentAcademicRemoteDataSource(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

final academicAdminRemoteDataSourceProvider =
    Provider<AcademicAdminRemoteDataSource>((ref) {
  return AcademicAdminRemoteDataSource(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

final teacherClassesProvider =
    FutureProvider.autoDispose<List<AcademicClassModel>>((ref) async {
  final dataSource = ref.watch(teacherAcademicRemoteDataSourceProvider);
  return dataSource.fetchMyClasses();
});

final teacherClassDetailsProvider = FutureProvider.autoDispose
    .family<ClassDetailModel?, int>((ref, classId) async {
  final dataSource = ref.watch(teacherAcademicRemoteDataSourceProvider);
  return dataSource.fetchClassDetails(classId);
});

/// Unified subject details provider — used by Student, Teacher, and Admin views.
/// Calls GET /api/academic/subjects/{id}/details
final subjectDetailsProvider = FutureProvider.autoDispose
    .family<ClassDetailModel?, int>((ref, subjectId) async {
  final dataSource = ref.watch(teacherAcademicRemoteDataSourceProvider);
  return dataSource.fetchClassDetails(subjectId);
});

final studentClassDetailsProvider =
    FutureProvider.autoDispose<ClassDetailModel?>((ref) async {
  final dataSource = ref.watch(studentAcademicRemoteDataSourceProvider);
  return dataSource.fetchMyClassDetails();
});

// ── Suspend / Activate subject (Admin only) ──────────────────────────────────

/// PUT /api/academic/subjects/{id}/suspend
Future<ClassDetailModel> suspendSubject(WidgetRef ref, int subjectId) async {
  final ds = ref.read(academicAdminRemoteDataSourceProvider);
  final result = await ds.suspendClass(subjectId);
  ref.invalidate(subjectDetailsProvider(subjectId));
  return result;
}

/// PUT /api/academic/subjects/{id}/activate
Future<ClassDetailModel> activateSubject(WidgetRef ref, int subjectId) async {
  final ds = ref.read(academicAdminRemoteDataSourceProvider);
  final result = await ds.activateClass(subjectId);
  ref.invalidate(subjectDetailsProvider(subjectId));
  return result;
}

// ── Suspend / Activate student in subject (Teacher & Admin) ─────────────────

/// PUT /api/academic/subjects/{subjectId}/students/{studentId}/suspend
Future<ClassDetailModel> suspendStudentInSubject(
  WidgetRef ref, {
  required int subjectId,
  required int studentId,
}) async {
  final ds = ref.read(academicAdminRemoteDataSourceProvider);
  final result = await ds.suspendStudentInSubject(subjectId, studentId);
  ref.invalidate(subjectDetailsProvider(subjectId));
  return result;
}

/// PUT /api/academic/subjects/{subjectId}/students/{studentId}/activate
Future<ClassDetailModel> activateStudentInSubject(
  WidgetRef ref, {
  required int subjectId,
  required int studentId,
}) async {
  final ds = ref.read(academicAdminRemoteDataSourceProvider);
  final result = await ds.activateStudentInSubject(subjectId, studentId);
  ref.invalidate(subjectDetailsProvider(subjectId));
  return result;
}
