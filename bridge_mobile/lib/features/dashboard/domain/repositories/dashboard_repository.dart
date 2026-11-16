import '../entities/dashboard_metric.dart';
import '../entities/subject.dart';

/// Abstract contract for the dashboard feature data layer.
abstract class DashboardRepository {
  /// Fetches admin metrics from GET /api/admin/dashboard
  Future<List<DashboardMetric>> getAdminDashboard();

  /// Fetches the current student's subjects from GET /api/academic/subjects/my-subjects
  Future<List<Subject>> getMySubjects();
}
