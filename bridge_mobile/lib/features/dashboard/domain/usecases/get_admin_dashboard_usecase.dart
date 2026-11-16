import '../entities/dashboard_metric.dart';
import '../repositories/dashboard_repository.dart';

/// Single-responsibility use-case: fetch admin dashboard metrics.
class GetAdminDashboardUseCase {
  final DashboardRepository _repository;

  const GetAdminDashboardUseCase(this._repository);

  Future<List<DashboardMetric>> call() => _repository.getAdminDashboard();
}
