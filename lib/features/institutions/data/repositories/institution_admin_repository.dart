import 'package:dio/dio.dart';

import '../datasources/institution_admin_remote_datasource.dart';
import '../../domain/entities/institution_entities.dart';

/// Bridges the remote data source to the presentation layer.
class InstitutionAdminRepository {
  final InstitutionAdminRemoteDataSource _dataSource;

  const InstitutionAdminRepository(this._dataSource);

  Future<InstitutionRegistrationResult> registerInstitution({
    required String institutionName,
    required String institutionCode,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required List<MapEntry<String, MultipartFile>> documents,
  }) {
    return _dataSource.registerInstitution(
      institutionName: institutionName,
      institutionCode: institutionCode,
      adminName: adminName,
      adminEmail: adminEmail,
      adminPassword: adminPassword,
      documents: documents,
    );
  }

  Future<List<PendingInstitution>> getPendingInstitutions() {
    return _dataSource.getPendingInstitutions();
  }

  Future<void> approveInstitution(int institutionId) {
    return _dataSource.approveInstitution(institutionId);
  }

  Future<void> rejectInstitution(int institutionId, String reason) {
    return _dataSource.rejectInstitution(institutionId, reason);
  }

  Future<List<ManagedInstitution>> getManagedInstitutions() {
    return _dataSource.getManagedInstitutions();
  }

  Future<void> suspendInstitution(int institutionId) {
    return _dataSource.suspendInstitution(institutionId);
  }

  Future<void> reactivateInstitution(int institutionId) {
    return _dataSource.reactivateInstitution(institutionId);
  }
}
