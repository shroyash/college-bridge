import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin_users/domain/entities/teacher_assignment.dart';
import '../../../admin_users/domain/usecases/manage_teacher_assignments_usecase.dart';
import '../../domain/usecases/get_my_subjects_usecase.dart';
import 'dashboard_state.dart';

/// StateNotifier for Teacher Dashboard — fetches and holds teacher class assignments.
class TeacherDashboardNotifier
    extends StateNotifier<DashboardState<List<TeacherAssignment>>> {
  final ManageTeacherAssignmentsUseCase _manageUseCase;
  final GetMySubjectsUseCase _getMySubjectsUseCase;

  TeacherDashboardNotifier(this._manageUseCase, this._getMySubjectsUseCase)
      : super(const DashboardInitial());

  /// Fetch teacher classes — use the `my-subjects` endpoint and map to
  /// `TeacherAssignment` so the UI does not need changes.
  Future<void> fetchTeacherAssignments([int teacherId = 0]) async {
    state = const DashboardLoading();
    try {
      int idToFetch = teacherId;
      if (idToFetch <= 0) {
        final profile = await _manageUseCase.getMyProfile();
        idToFetch = profile.teacherId ?? profile.userId;
      }

      // Call the teacher/student "my-subjects" endpoint which returns List<Subject>
      final subjects = await _getMySubjectsUseCase();

      // Map Subject -> TeacherAssignment for existing UI compatibility
      final assignments = subjects
          .map((s) => TeacherAssignment(
                assignmentId: s.subjectId,
                subjectId: s.subjectId,
                subjectName: s.name,
                faculty: s.faculty,
                semester: s.semester,
              ))
          .toList();

      state = DashboardSuccess(assignments);
    } catch (e) {
      state = DashboardFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
