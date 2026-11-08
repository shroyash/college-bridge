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
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../domain/entities/holiday_notice_enums.dart';
import '../controllers/holiday_notice_providers.dart';
import '../controllers/official_notices_state.dart';

class OfficialNoticesScreen extends ConsumerStatefulWidget {
  const OfficialNoticesScreen({super.key});

  @override
  ConsumerState<OfficialNoticesScreen> createState() => _OfficialNoticesScreenState();
}

class _OfficialNoticesScreenState extends ConsumerState<OfficialNoticesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadNotices);
  }

  void _loadNotices() {
    final authState = ref.read(authNotifierProvider);
    int institutionId = 1;
    if (authState is AuthSuccess) {
      institutionId = authState.user.institution?.institutionId ?? 1;
    }

    final todayNepal = NepalTimeHelper.nowInNepal();
    final todayStr =
        '${todayNepal.year}-${todayNepal.month.toString().padLeft(2, '0')}-${todayNepal.day.toString().padLeft(2, '0')}';

    ref.read(officialNoticesNotifierProvider.notifier).fetchNotice(
          institutionId: institutionId,
          date: todayStr,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(officialNoticesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Campus Holiday Notices',
          style: AppTypography.titleLarge().copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimaryLight),
            onPressed: _loadNotices,
          ),
        ],
      ),
      body: switch (state) {
        OfficialNoticesLoading() => const Center(child: AppLoading()),
        OfficialNoticesError(:final message) => AppErrorState(
            message: message,
            onRetry: _loadNotices,
          ),
        OfficialNoticesLoaded(:final notices) => notices.isEmpty
            ? RefreshIndicator(
                onRefresh: () async => _loadNotices(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    const AppEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No Notices',
                      message: 'No holiday notices have been published yet.',
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => _loadNotices(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: notices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = notices[index];
                    final isClosed = item.variant == NoticeVariant.CLOSED;

                    return InkWell(
                      onTap: () {
                        context.push('/holiday-notices/detail', extra: item);
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isClosed
                                        ? const Color(0xFFFEE2E2)
                                        : const Color(0xFFECFDF5),
                                    borderRadius: AppRadius.borderCircular,
                                  ),
                                  child: Text(
                                    item.variant.badgeText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isClosed
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                ),
                                Text(
                                  NepalTimeHelper.formatReadableDate(item.dateAd),
                                  style: AppTypography.bodySmall().copyWith(
                                    color: AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              item.title,
                              style: AppTypography.titleMedium().copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.holidayName,
                              style: AppTypography.bodySmall().copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              item.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium().copyWith(
                                color: AppColors.textSecondaryLight,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        OfficialNoticesInitial() => const Center(child: AppLoading()),
      },
    );
  }
}
