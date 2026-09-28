import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bridge_mobile/core/network/api_client.dart';
import '../../data/datasources/doubt_remote_data_source.dart';
import '../../data/models/doubt_model.dart';
import '../../data/models/doubt_summary_model.dart';

final doubtRemoteDataSourceProvider = Provider<DoubtRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DoubtRemoteDataSource(apiClient);
});

final subjectDoubtSummaryProvider =
    FutureProvider.family.autoDispose<DoubtSummaryModel, int?>((ref, subjectId) async {
  final ds = ref.watch(doubtRemoteDataSourceProvider);
  return ds.getDoubtSummary(subjectId: subjectId);
});

final doubtsListProvider = FutureProvider.family.autoDispose<
    List<DoubtModel>,
    ({int? subjectId, String? search})>((ref, arg) async {
  final ds = ref.watch(doubtRemoteDataSourceProvider);
  return ds.getDoubts(
    subjectId: arg.subjectId,
    search: arg.search,
  );
});

final doubtDetailProvider =
    FutureProvider.family.autoDispose<DoubtModel, int>((ref, doubtId) async {
  final ds = ref.watch(doubtRemoteDataSourceProvider);
  return ds.getDoubt(doubtId);
});
