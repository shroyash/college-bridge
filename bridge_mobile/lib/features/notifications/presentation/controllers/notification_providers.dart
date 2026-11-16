import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../academics/data/models/academic_level_model.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_notifier.dart';
import 'notification_state.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRemoteDataSource(apiClient);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dataSource = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(dataSource);
});

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationNotifierProvider).unreadCount;
});

final filteredNotificationListProvider =
    Provider<List<NotificationItem>>((ref) {
  return ref.watch(notificationNotifierProvider).filteredItems;
});

final notificationSubjectListProvider =
    FutureProvider.family<List<SubjectModel>, String?>((ref, role) async {
  final dataSource = ref.watch(notificationRemoteDataSourceProvider);
  return dataSource.fetchSubjectsForRole(role);
});

final notificationLevelListProvider =
    FutureProvider.family<List<AcademicLevelModel>, String?>((ref, role) async {
  final dataSource = ref.watch(notificationRemoteDataSourceProvider);
  return dataSource.fetchLevelsForRole(role);
});
