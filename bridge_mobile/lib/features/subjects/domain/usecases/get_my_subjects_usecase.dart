import '../entities/subject.dart';
import 'package:bridge_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Single-responsibility use-case: fetch the current student's subjects.
class GetMySubjectsUseCase {
  final DashboardRepository _repository;

  const GetMySubjectsUseCase(this._repository);

  Future<List<Subject>> call() => _repository.getMySubjects();
}
