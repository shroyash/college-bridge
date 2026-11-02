import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/support_remote_datasource.dart';
import '../../data/models/support_ticket_model.dart';

final supportRemoteDataSourceProvider =
    Provider<SupportRemoteDataSource>((ref) {
  return SupportRemoteDataSource(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

class SuperAdminTicketsState {
  final List<SupportTicketModel> tickets;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool isLoading;
  final String searchQuery;
  final String selectedStatus;
  final String? errorMessage;

  const SuperAdminTicketsState({
    this.tickets = const [],
    this.currentPage = 0,
    this.totalPages = 0,
    this.totalElements = 0,
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedStatus = 'ALL',
    this.errorMessage,
  });

  SuperAdminTicketsState copyWith({
    List<SupportTicketModel>? tickets,
    int? currentPage,
    int? totalPages,
    int? totalElements,
    bool? isLoading,
    String? searchQuery,
    String? selectedStatus,
    String? errorMessage,
  }) {
    return SuperAdminTicketsState(
      tickets: tickets ?? this.tickets,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      errorMessage: errorMessage,
    );
  }
}

class SuperAdminTicketsNotifier extends StateNotifier<SuperAdminTicketsState> {
  final SupportRemoteDataSource _dataSource;

  SuperAdminTicketsNotifier(this._dataSource)
      : super(const SuperAdminTicketsState());

  Future<void> loadTickets({int page = 0, String? search, String? status}) async {
    final query = search ?? state.searchQuery;
    final stat = status ?? state.selectedStatus;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      searchQuery: query,
      selectedStatus: stat,
    );

    try {
      final result = await _dataSource.getSuperAdminTickets(
        search: query.isNotEmpty ? query : null,
        status: stat,
        page: page,
        size: 20,
      );

      state = state.copyWith(
        tickets: result.tickets,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalElements: result.totalElements,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void search(String query) {
    loadTickets(page: 0, search: query.trim());
  }

  void filterStatus(String status) {
    loadTickets(page: 0, status: status);
  }

  Future<bool> updateTicketStatus(int ticketId, String newStatus) async {
    try {
      final updated = await _dataSource.updateTicketStatus(ticketId, newStatus);
      final updatedList = state.tickets.map((t) {
        return t.ticketId == ticketId ? updated : t;
      }).toList();

      state = state.copyWith(tickets: updatedList);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final superAdminTicketsProvider = StateNotifierProvider<
    SuperAdminTicketsNotifier, SuperAdminTicketsState>((ref) {
  return SuperAdminTicketsNotifier(ref.watch(supportRemoteDataSourceProvider));
});
