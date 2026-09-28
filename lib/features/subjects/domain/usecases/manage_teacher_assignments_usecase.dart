import 'dart:io';

import '../entities/teacher_assignment.dart';
import 'package:bridge_mobile/features/admin_users/domain/entities/user_profile.dart';
import 'package:bridge_mobile/features/admin_users/domain/repositories/admin_user_repository.dart';
import '../entities/subject.dart';

class ManageTeacherAssignmentsUseCase {
  final AdminUserRepository _repository;

  ManageTeacherAssignmentsUseCase(this._repository);

  Future<UserProfile> getMyProfile() {
    return _repository.getMyProfile();
  }

  Future<List<TeacherAssignment>> getTeacherAssignments(int teacherId) {
    return _repository.getTeacherAssignments(teacherId);
  }

  Future<List<TeacherAssignment>> saveAssignments(
    int teacherId,
    List<int> subjectIds,
  ) {
    return _repository.replaceTeacherAssignments(teacherId, subjectIds);
  }

  Future<List<Subject>> getAllSubjects() {
    return _repository.getAllSubjects();
  }

  Future<List<Subject>> searchSubjects(String query) {
    return _repository.searchSubjects(query);
  }

  Future<UserProfile> updateProfile({required String name}) {
    return _repository.updateProfile(name: name);
  }

  Future<String> uploadProfileImage(File imageFile) {
    return _repository.uploadProfileImage(imageFile);
  }

  Future<void> logout() {
    return _repository.logout();
  }
}
