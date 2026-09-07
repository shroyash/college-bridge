import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bridge_mobile/core/network/api_client.dart';
import 'package:bridge_mobile/core/storage/secure_storage_service.dart';
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
