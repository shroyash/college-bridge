import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subject.dart';
import '../../domain/usecases/get_my_subjects_usecase.dart';
import 'dashboard_state.dart';

/// StateNotifier for Student Dashboard — fetches and holds subjects.
class StudentDashboardNotifier
    extends StateNotifier<DashboardState<List<Subject>>> {
  final GetMySubjectsUseCase _getMySubjectsUseCase;

  StudentDashboardNotifier(this._getMySubjectsUseCase)
      : super(const DashboardInitial());

  Future<void> fetchMySubjects() async {
    state = const DashboardLoading();
    try {
      final subjects = await _getMySubjectsUseCase();
      state = DashboardSuccess(subjects);
    } catch (e) {
      state = DashboardFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
