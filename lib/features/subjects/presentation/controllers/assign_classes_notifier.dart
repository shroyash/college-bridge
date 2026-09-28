import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subject.dart';
import '../../domain/entities/teacher_assignment.dart';
import '../../domain/usecases/manage_teacher_assignments_usecase.dart';

abstract class AssignClassesState {
  const AssignClassesState();
}

class AssignClassesLoading extends AssignClassesState {
  const AssignClassesLoading();
}

class AssignClassesSuccess extends AssignClassesState {
  final List<TeacherAssignment> assignedClasses;
  final List<Subject> availableClasses;
  final bool isSaving;
  final String searchQuery;

  const AssignClassesSuccess({
    required this.assignedClasses,
    required this.availableClasses,
    this.isSaving = false,
    this.searchQuery = '',
  });

  int get totalCredits {
    // Return total calculated credits or count
    return assignedClasses.length * 3; // Estimated default or sum
  }

  AssignClassesSuccess copyWith({
    List<TeacherAssignment>? assignedClasses,
    List<Subject>? availableClasses,
    bool? isSaving,
    String? searchQuery,
  }) {
    return AssignClassesSuccess(
      assignedClasses: assignedClasses ?? this.assignedClasses,
      availableClasses: availableClasses ?? this.availableClasses,
      isSaving: isSaving ?? this.isSaving,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class AssignClassesFailure extends AssignClassesState {
  final String message;
  const AssignClassesFailure(this.message);
}

class SaveAssignmentsResult {
  final bool success;
  final String? errorMessage;
  const SaveAssignmentsResult({required this.success, this.errorMessage});
}

class AssignClassesNotifier extends StateNotifier<AssignClassesState> {
  final ManageTeacherAssignmentsUseCase _useCase;
  final int teacherId;

  List<TeacherAssignment> _assigned = [];
  List<Subject> _allAvailable = [];

  AssignClassesNotifier({
    required ManageTeacherAssignmentsUseCase useCase,
    required this.teacherId,
  })  : _useCase = useCase,
        super(const AssignClassesLoading());

  Future<void> loadAssignments() async {
    state = const AssignClassesLoading();
    try {
      final assignments = await _useCase.getTeacherAssignments(teacherId);
      final allSubjects = await _useCase.getAllSubjects();

      _assigned = List.from(assignments);
      _allAvailable = List.from(allSubjects);

      _updateSuccessState();
    } catch (e) {
      state = AssignClassesFailure(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void assignSubject(Subject subject) {
    if (state is! AssignClassesSuccess) return;

    // Check if already assigned
    final isAlreadyAssigned = _assigned.any((a) => a.subjectId == subject.subjectId);
    if (!isAlreadyAssigned) {
      _assigned.add(
        TeacherAssignment(
          assignmentId: 0,
          subjectId: subject.subjectId,
          subjectName: subject.name,
          faculty: subject.faculty,
          semester: subject.semester,
        ),
      );
      _updateSuccessState();
    }
  }

  void removeAssignment(int subjectId) {
    if (state is! AssignClassesSuccess) return;

    _assigned.removeWhere((a) => a.subjectId == subjectId);
    _updateSuccessState();
  }

  Future<SaveAssignmentsResult> saveAssignments() async {
    if (state is! AssignClassesSuccess) {
      return const SaveAssignmentsResult(success: false, errorMessage: 'Invalid state');
    }
    final currentState = state as AssignClassesSuccess;

    state = currentState.copyWith(isSaving: true);
    try {
      final subjectIds = _assigned.map((a) => a.subjectId).toList();
      final updated = await _useCase.saveAssignments(teacherId, subjectIds);
      _assigned = List.from(updated);
      _updateSuccessState();
      return const SaveAssignmentsResult(success: true);
    } catch (e) {
      _updateSuccessState();
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      return SaveAssignmentsResult(success: false, errorMessage: errorMsg);
    }
  }

  void searchAvailable(String query) {
    if (state is! AssignClassesSuccess) return;
    _updateSuccessState(searchQuery: query);
  }

  void _updateSuccessState({String searchQuery = ''}) {
    final assignedIds = _assigned.map((a) => a.subjectId).toSet();
    final availableFiltered = _allAvailable.where((s) {
      final isNotAssigned = !assignedIds.contains(s.subjectId);
      if (searchQuery.isEmpty) return isNotAssigned;
      final matchesQuery = s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          s.faculty.toLowerCase().contains(searchQuery.toLowerCase());
      return isNotAssigned && matchesQuery;
    }).toList();

    state = AssignClassesSuccess(
      assignedClasses: List.from(_assigned),
      availableClasses: availableFiltered,
      isSaving: false,
      searchQuery: searchQuery,
    );
  }
}
