import 'package:dio/dio.dart';

import '../../../../app/constants/api_constants.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/support_ticket_model.dart';

class PagedTickets {
  final List<SupportTicketModel> tickets;
  final int currentPage;
  final int pageSize;
  final int totalElements;
  final int totalPages;

  const PagedTickets({
    required this.tickets,
    required this.currentPage,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
  });
}

class SupportRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  const SupportRemoteDataSource(this._apiClient, this._storage);

  Future<Options> _authOptions() async {
    final token = await _storage.getAccessToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Exception _mapDioException(DioException e) {
    String msg = '';
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        msg = data['message'] as String? ?? '';
      }
    } catch (_) {}
    return Exception(msg.isNotEmpty ? msg : 'An unexpected error occurred.');
  }

  /// POST /api/support/tickets
  Future<SupportTicketModel> createTicket({
    required String category,
    required String subject,
    required String description,
  }) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.supportTickets,
        data: {
          'category': category,
          'subject': subject,
          'description': description,
        },
        options: options,
      );

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return SupportTicketModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// GET /api/support/tickets/my
  Future<List<SupportTicketModel>> getMyTickets() async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.supportTicketsMy,
        options: options,
      );

      final list = response.data?['data'] as List? ?? [];
      return list
          .map((e) => SupportTicketModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// GET /api/super-admin/tickets
  Future<PagedTickets> getSuperAdminTickets({
    String? search,
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final options = await _authOptions();
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status != 'ALL' && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.superAdminTickets,
        queryParameters: queryParams,
        options: options,
      );

      final body = response.data?['data'] as Map<String, dynamic>? ?? {};
      final content = body['content'] as List? ?? [];
      return PagedTickets(
        tickets: content
            .map((e) => SupportTicketModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentPage: body['currentPage'] as int? ?? page,
        pageSize: body['pageSize'] as int? ?? size,
        totalElements: (body['totalElements'] as num?)?.toInt() ?? 0,
        totalPages: body['totalPages'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// PATCH /api/super-admin/tickets/{id}/status
  Future<SupportTicketModel> updateTicketStatus(
      int ticketId, String status) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.patch<Map<String, dynamic>>(
        ApiEndpoints.superAdminTicketStatus(ticketId),
        data: {'status': status},
        options: options,
      );

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return SupportTicketModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }
}

