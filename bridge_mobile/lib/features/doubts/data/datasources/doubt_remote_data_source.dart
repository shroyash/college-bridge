import 'package:bridge_mobile/core/network/api_client.dart';
import '../models/doubt_model.dart';
import '../models/doubt_answer_model.dart';
import '../models/doubt_summary_model.dart';

class DoubtRemoteDataSource {
  final ApiClient _apiClient;

  const DoubtRemoteDataSource(this._apiClient);

  Future<DoubtModel> createDoubt({
    required int subjectId,
    required String question,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/doubts',
      data: {
        'subjectId': subjectId,
        'question': question,
      },
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return DoubtModel.fromJson(data);
  }

  Future<List<DoubtModel>> getDoubts({
    int? subjectId,
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (subjectId != null && subjectId > 0) {
      queryParams['subjectId'] = subjectId;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/doubts',
      queryParameters: queryParams,
    );

    final dataMap = response.data!['data'] as Map<String, dynamic>?;
    final content = dataMap?['content'] as List? ?? [];
    return content.map((e) => DoubtModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<DoubtModel> getDoubt(int doubtId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/doubts/$doubtId',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return DoubtModel.fromJson(data);
  }

  Future<DoubtSummaryModel> getDoubtSummary({int? subjectId}) async {
    final queryParams = <String, dynamic>{};
    if (subjectId != null && subjectId > 0) {
      queryParams['subjectId'] = subjectId;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/doubts/summary',
      queryParameters: queryParams,
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return DoubtSummaryModel.fromJson(data);
  }

  Future<DoubtAnswerModel> answerDoubt({
    required int doubtId,
    required String answer,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/doubts/$doubtId/answers',
      data: {
        'answer': answer,
      },
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return DoubtAnswerModel.fromJson(data);
  }

  Future<void> verifyAnswer(int answerId) async {
    await _apiClient.dio.patch<dynamic>(
      '/api/doubt-answers/$answerId/verify',
    );
  }

  Future<DoubtModel> markHelpful(int doubtId) async {
    final response = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/api/doubts/$doubtId/helpful',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return DoubtModel.fromJson(data);
  }
}
