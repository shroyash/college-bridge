import '../../domain/entities/dashboard_metric.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

/// Concrete implementation of [DashboardRepository].
/// Bridges the remote datasource to the domain layer.
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  const DashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<DashboardMetric>> getAdminDashboard() async {
    return _remoteDataSource.fetchAdminDashboard();
  }

  @override
  Future<List<Subject>> getMySubjects() async {
    return _remoteDataSource.fetchMySubjects();
  }
}
