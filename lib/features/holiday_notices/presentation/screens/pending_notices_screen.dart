import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/helpers/nepal_time_helper.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../controllers/holiday_notice_providers.dart';
import '../controllers/pending_notice_state.dart';

class PendingNoticesScreen extends ConsumerStatefulWidget {
  const PendingNoticesScreen({super.key});

  @override
  ConsumerState<PendingNoticesScreen> createState() => _PendingNoticesScreenState();
}

class _PendingNoticesScreenState extends ConsumerState<PendingNoticesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(pendingNoticeNotifierProvider.notifier).fetchPendingNotice();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendingNoticeNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Pending Holiday Notices',
          style: AppTypography.titleLarge().copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimaryLight),
            onPressed: () {
              ref.read(pendingNoticeNotifierProvider.notifier).fetchPendingNotice();
            },
          ),
        ],
      ),
      body: switch (state) {
        PendingNoticeLoading() => const Center(child: AppLoading()),
        PendingNoticeError(:final message) => AppErrorState(
            message: message,
            onRetry: () {
              ref.read(pendingNoticeNotifierProvider.notifier).fetchPendingNotice();
            },
          ),
        PendingNoticeLoaded(:final notice) => notice == null
            ? RefreshIndicator(
                onRefresh: () async {
                  await ref.read(pendingNoticeNotifierProvider.notifier).fetchPendingNotice();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    const AppEmptyState(
                      icon: Icons.event_available_rounded,
                      title: 'All Caught Up',
                      message: 'No holiday notices need your decision.',
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.read(pendingNoticeNotifierProvider.notifier).fetchPendingNotice();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    InkWell(
                      onTap: () {
                        context.push('/admin/holiday-notices/pending', extra: notice);
                      },
                      borderRadius: AppRadius.borderMd,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFEF3C7),
                                    borderRadius: AppRadius.borderCircular,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.pending_actions_rounded,
                                          size: 14, color: Color(0xFFB45309)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Needs Decision',
                                        style: AppTypography.labelMedium().copyWith(
                                          color: const Color(0xFFB45309),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  NepalTimeHelper.relativeLabel(notice.holidayDateAd),
                                  style: AppTypography.labelMedium().copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              notice.holidayName,
                              style: AppTypography.titleLarge().copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${NepalTimeHelper.formatReadableDate(notice.holidayDateAd)} · ${notice.holidayDateBs} BS',
                              style: AppTypography.bodyMedium().copyWith(
                                color: AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (notice.holidayScope != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Scope: ${notice.holidayScope}',
                                style: AppTypography.bodySmall().copyWith(
                                  color: AppColors.textMutedLight,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Review drafts & publish',
                                  style: AppTypography.labelMedium().copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        PendingNoticeInitial() => const Center(child: AppLoading()),
      },
    );
  }
}
