import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/create_notification_request_model.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;

  NotificationNotifier(this._repository) : super(const NotificationState());

  /// Fetch initial inbox items or refresh
  Future<void> fetchInbox({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    if (refresh) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final pageResponse = await _repository.getNotifications(page: 0, size: 20);
      final count = await _repository.getUnreadCount();

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        items: List<NotificationItem>.from(pageResponse.content),
        currentPage: 0,
        hasMore: !pageResponse.last && pageResponse.pageNumber < pageResponse.totalPages - 1,
        unreadCount: count,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Load more items for infinite scroll
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final pageResponse = await _repository.getNotifications(page: nextPage, size: 20);

      final combined = List<NotificationItem>.from(state.items)
        ..addAll(pageResponse.content);

      state = state.copyWith(
        isLoadingMore: false,
        items: combined,
        currentPage: nextPage,
        hasMore: !pageResponse.last && pageResponse.pageNumber < pageResponse.totalPages - 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Refresh unread count only
  Future<void> fetchUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (_) {
      // Non-blocking fail
    }
  }

  /// Mark an unread notification as read (optimistic update + API call)
  Future<void> markAsRead(int notificationId) async {
    final existingIndex = state.items.indexWhere((n) => n.notificationId == notificationId);
    if (existingIndex != -1) {
      final item = state.items[existingIndex];
      if (item.isRead) return; // Already read

      // Optimistic update
      final updatedList = List<NotificationItem>.from(state.items);
      updatedList[existingIndex] = item.copyWith(isRead: true);
      final newCount = (state.unreadCount - 1).clamp(0, 999999);

      state = state.copyWith(
        items: updatedList,
        unreadCount: newCount,
      );
    }

    try {
      await _repository.markAsRead(notificationId);
    } catch (e) {
      // Revert if API failed and item exists in local state
      if (existingIndex != -1) {
        final revertedList = List<NotificationItem>.from(state.items);
        revertedList[existingIndex] = state.items[existingIndex].copyWith(isRead: false);
        state = state.copyWith(
          items: revertedList,
          unreadCount: state.unreadCount + 1,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  /// Find an item by its notification ID from local state
  NotificationItem? getById(int notificationId) {
    try {
      return state.items.firstWhere((n) => n.notificationId == notificationId);
    } catch (_) {
      return null;
    }
  }

  /// Switch filter: ALL, UNREAD, READ
  void setFilter(NotificationFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// Dispatch a new notification (Admins & Teachers)
  Future<bool> broadcastNotification(CreateNotificationRequestModel request) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _repository.createNotification(request);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Notification sent successfully!',
      );
      // Refresh inbox after sending
      await fetchInbox(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
