import 'dart:io';

import 'package:bridge_mobile/features/subjects/domain/entities/teacher_assignment.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/admin_user_repository.dart';
import 'package:bridge_mobile/features/subjects/domain/entities/subject.dart';
import '../datasources/admin_user_remote_datasource.dart';

class AdminUserRepositoryImpl implements AdminUserRepository {
  final AdminUserRemoteDataSource _remoteDataSource;

  AdminUserRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<UserProfile>> filterUsers({
    required String role,
    required String status,
    int page = 0,
    int size = 20,
  }) {
    return _remoteDataSource.filterUsers(
      role: role,
      status: status,
      page: page,
      size: size,
    );
  }

  @override
  Future<List<UserProfile>> searchUsers({
    required String query,
    int page = 0,
    int size = 20,
  }) {
    return _remoteDataSource.searchUsers(
      query: query,
      page: page,
      size: size,
    );
  }

  @override
  Future<void> suspendUser(int userId) {
    return _remoteDataSource.suspendUser(userId);
  }

  @override
  Future<void> activateUser(int userId) {
    return _remoteDataSource.activateUser(userId);
  }

  @override
  Future<void> registerTeacher({
    required String name,
    required String email,
    required String password,
  }) {
    return _remoteDataSource.registerTeacher(
      name: name,
      email: email,
      password: password,
    );
  }

  @override
  Future<List<TeacherAssignment>> getTeacherAssignments(int teacherId) {
    return _remoteDataSource.getTeacherAssignments(teacherId);
  }

  @override
  Future<List<TeacherAssignment>> replaceTeacherAssignments(
    int teacherId,
    List<int> subjectIds,
  ) {
    return _remoteDataSource.replaceTeacherAssignments(teacherId, subjectIds);
  }

  @override
  Future<List<Subject>> getStudentSubjects(int studentId) {
    return _remoteDataSource.getStudentSubjects(studentId);
  }

  @override
  Future<List<Subject>> getAllSubjects() {
    return _remoteDataSource.getAllSubjects();
  }

  @override
  Future<List<Subject>> searchSubjects(String name) {
    return _remoteDataSource.searchSubjects(name);
  }

  @override
  Future<UserProfile> getMyProfile() {
    return _remoteDataSource.getMyProfile();
  }

  @override
  Future<UserProfile> updateProfile({required String name}) {
    return _remoteDataSource.updateProfile(name: name);
  }

  @override
  Future<String> uploadProfileImage(File imageFile) {
    return _remoteDataSource.uploadProfileImage(imageFile);
  }

  @override
  Future<void> logout() {
    return _remoteDataSource.logout();
  }
}
