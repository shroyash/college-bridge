import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/notification_item.dart';
import '../controllers/notification_notifier.dart';
import '../controllers/notification_providers.dart';
import '../controllers/notification_state.dart';
import '../widgets/notification_tile.dart';
import 'broadcast_notification_screen.dart';
import 'notification_detail_screen.dart';

class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState
    extends ConsumerState<NotificationInboxScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      ref.read(notificationNotifierProvider.notifier).fetchInbox();
      _loadRole();
    });
  }

  Future<void> _loadRole() async {
    final storage = ref.read(secureStorageProvider);
    final role = await storage.getUserRole();
    if (mounted) {
      setState(() => _userRole = role);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _canBroadcast =>
      _userRole == 'ADMIN' ||
      _userRole == 'TEACHER' ||
      _userRole == 'SUPER_ADMIN';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.unreadCount} new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: () => notifier.fetchInbox(refresh: true),
          ),
          if (_canBroadcast)
            IconButton(
              tooltip: 'Send Broadcast',
              icon: const Icon(Icons.add_alert_rounded, color: Color(0xFF2563EB)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BroadcastNotificationScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter row
          _buildFilterRow(state, notifier),
          // Content
          Expanded(
            child: _buildBody(state, notifier),
          ),
        ],
      ),
      floatingActionButton: _canBroadcast
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BroadcastNotificationScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(Icons.campaign_rounded, color: Colors.white),
              label: const Text(
                'Broadcast',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildFilterRow(
      NotificationState state, NotificationNotifier notifier) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All (${state.items.length})',
            isSelected: state.filter == NotificationFilter.all,
            onSelected: () => notifier.setFilter(NotificationFilter.all),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Unread (${state.unreadCount})',
            isSelected: state.filter == NotificationFilter.unread,
            onSelected: () => notifier.setFilter(NotificationFilter.unread),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Read',
            isSelected: state.filter == NotificationFilter.read,
            onSelected: () => notifier.setFilter(NotificationFilter.read),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildBody(NotificationState state, NotificationNotifier notifier) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2563EB),
        ),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF475569)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => notifier.fetchInbox(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = state.filteredItems;

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => notifier.fetchInbox(refresh: true),
        color: const Color(0xFF2563EB),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_off_outlined,
                        size: 48,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.filter == NotificationFilter.unread
                          ? 'No unread notifications'
                          : 'No notifications yet',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'You are all caught up!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.fetchInbox(refresh: true),
      color: const Color(0xFF2563EB),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final item = items[index];
          return NotificationTile(
            notification: item,
            onTap: () => _openNotificationDetails(item),
          );
        },
      ),
    );
  }

  void _openNotificationDetails(NotificationItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(
          notificationId: item.notificationId,
          initialItem: item,
        ),
      ),
    );
  }

}
