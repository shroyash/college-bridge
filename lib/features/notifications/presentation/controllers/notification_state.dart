import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_item.dart';

enum NotificationFilter { all, unread, read }

class NotificationState extends Equatable {
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isSubmitting;
  final List<NotificationItem> items;
  final int currentPage;
  final bool hasMore;
  final int unreadCount;
  final NotificationFilter filter;
  final String? errorMessage;
  final String? successMessage;

  const NotificationState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.items = const [],
    this.currentPage = 0,
    this.hasMore = false,
    this.unreadCount = 0,
    this.filter = NotificationFilter.all,
    this.errorMessage,
    this.successMessage,
  });

  List<NotificationItem> get filteredItems {
    switch (filter) {
      case NotificationFilter.unread:
        return items.where((item) => !item.isRead).toList();
      case NotificationFilter.read:
        return items.where((item) => item.isRead).toList();
      case NotificationFilter.all:
        return items;
    }
  }

  NotificationState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isSubmitting,
    List<NotificationItem>? items,
    int? currentPage,
    bool? hasMore,
    int? unreadCount,
    NotificationFilter? filter,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isRefreshing,
        isLoadingMore,
        isSubmitting,
        items,
        currentPage,
        hasMore,
        unreadCount,
        filter,
        errorMessage,
        successMessage,
      ];
}
