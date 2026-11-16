import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dashboard_metric.dart';
import '../../domain/usecases/get_admin_dashboard_usecase.dart';
import 'dashboard_state.dart';

/// StateNotifier for Admin Dashboard — fetches and holds metrics.
class AdminDashboardNotifier
    extends StateNotifier<DashboardState<List<DashboardMetric>>> {
  final GetAdminDashboardUseCase _getAdminDashboardUseCase;

  AdminDashboardNotifier(this._getAdminDashboardUseCase)
      : super(const DashboardInitial());

  Future<void> fetchDashboard() async {
    state = const DashboardLoading();
    try {
      final metrics = await _getAdminDashboardUseCase();
      state = DashboardSuccess(metrics);
    } catch (e) {
      state = DashboardFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
