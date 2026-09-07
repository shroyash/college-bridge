import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/institution_admin_remote_datasource.dart';
import '../../data/repositories/institution_admin_repository.dart';
import 'institution_notifiers.dart';
import 'institution_state.dart';

// ── Data Layer ────────────────────────────────────────────────────────────────

final institutionAdminDataSourceProvider =
    Provider<InstitutionAdminRemoteDataSource>((ref) {
  return InstitutionAdminRemoteDataSource(ref.watch(apiClientProvider));
});

final institutionAdminRepositoryProvider =
    Provider<InstitutionAdminRepository>((ref) {
  return InstitutionAdminRepository(
      ref.watch(institutionAdminDataSourceProvider));
});

// ── Notifiers ─────────────────────────────────────────────────────────────────

final institutionRegistrationProvider = StateNotifierProvider<
    InstitutionRegistrationNotifier, InstitutionRegistrationState>((ref) {
  return InstitutionRegistrationNotifier(
      ref.watch(institutionAdminRepositoryProvider));
});

final pendingInstitutionsProvider = StateNotifierProvider<
    PendingInstitutionsNotifier, PendingInstitutionsState>((ref) {
  return PendingInstitutionsNotifier(
      ref.watch(institutionAdminRepositoryProvider));
});

final managedInstitutionsProvider = StateNotifierProvider<
    ManagedInstitutionsNotifier, ManagedInstitutionsState>((ref) {
  return ManagedInstitutionsNotifier(
      ref.watch(institutionAdminRepositoryProvider));
});
