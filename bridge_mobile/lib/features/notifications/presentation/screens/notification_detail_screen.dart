import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notification_target_type.dart';
import '../controllers/notification_providers.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final int notificationId;
  final NotificationItem? initialItem;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
    this.initialItem,
  });

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final item = widget.initialItem ??
          ref
              .read(notificationNotifierProvider.notifier)
              .getById(widget.notificationId);

      // If unread, mark as read on open
      if (item != null && !item.isRead) {
        ref
            .read(notificationNotifierProvider.notifier)
            .markAsRead(widget.notificationId);
      } else if (item == null) {
        // Fallback: trigger inbox fetch if not already in state
        ref.read(notificationNotifierProvider.notifier).fetchInbox();
        ref
            .read(notificationNotifierProvider.notifier)
            .markAsRead(widget.notificationId);
      }
    });
  }

  Color _getTypeColor(NotificationTargetType type) {
    switch (type) {
      case NotificationTargetType.INSTITUTION:
        return const Color(0xFF2563EB); // Blue
      case NotificationTargetType.CLASS:
        return const Color(0xFF9333EA); // Purple
      case NotificationTargetType.SUBJECT:
        return const Color(0xFF16A34A); // Green
      case NotificationTargetType.USERS:
        return const Color(0xFFD97706); // Amber
    }
  }

  IconData _getTypeIcon(NotificationTargetType type) {
    switch (type) {
      case NotificationTargetType.INSTITUTION:
        return Icons.business_rounded;
      case NotificationTargetType.CLASS:
        return Icons.class_rounded;
      case NotificationTargetType.SUBJECT:
        return Icons.menu_book_rounded;
      case NotificationTargetType.USERS:
        return Icons.person_rounded;
    }
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final year = local.year;
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);
    final item = state.items.cast<NotificationItem?>().firstWhere(
          (n) => n?.notificationId == widget.notificationId,
          orElse: () => widget.initialItem,
        );

    final title = item?.title ?? 'Notification #${widget.notificationId}';
    final body = item?.body ?? '';
    final senderName = item?.senderName.isNotEmpty == true
        ? item!.senderName
        : 'Administration';
    final targetType = item?.targetType ?? NotificationTargetType.INSTITUTION;
    final createdAt = item?.createdAt ?? DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notification Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Badge & Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getTypeColor(targetType).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(targetType),
                          size: 14,
                          color: _getTypeColor(targetType),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          targetType.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: _getTypeColor(targetType),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item?.isRead == true
                              ? Icons.mark_email_read_outlined
                              : Icons.mark_email_unread_outlined,
                          size: 13,
                          color: item?.isRead == true
                              ? const Color(0xFF64748B)
                              : const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item?.isRead == true ? 'Read' : 'Just read',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item?.isRead == true
                                ? const Color(0xFF64748B)
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // Sender and Date metadata
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFDBEAFE),
                      child: Text(
                        senderName.isNotEmpty
                            ? senderName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDateTime(createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 24),

              // Full Message Body
              Text(
                body.isNotEmpty ? body : 'No additional content provided.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
