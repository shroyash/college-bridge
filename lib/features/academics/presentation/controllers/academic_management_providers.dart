import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/academic_admin_remote_datasource.dart';
import 'academic_management_notifier.dart';
import 'academic_management_state.dart';


final academicAdminRemoteDataSourceProvider =
    Provider<AcademicAdminRemoteDataSource>((ref) {
  return AcademicAdminRemoteDataSource(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

final academicManagementNotifierProvider = StateNotifierProvider<
    AcademicManagementNotifier, AcademicManagementState>((ref) {
  return AcademicManagementNotifier(
    ref.watch(academicAdminRemoteDataSourceProvider),
  );
});
