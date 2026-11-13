import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/helpers/nepal_time_helper.dart';
import '../controllers/holiday_notice_providers.dart';
import '../controllers/pending_notice_state.dart';

class AdminHolidayBanner extends ConsumerWidget {
  const AdminHolidayBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingNoticeNotifierProvider);

    if (state is! PendingNoticeLoaded || state.notice == null) {
      return const SizedBox.shrink();
    }

    final notice = state.notice!;
    final relative = NepalTimeHelper.relativeLabel(notice.holidayDateAd);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Holiday Notice Proposal',
                    style: AppTypography.labelLarge().copyWith(
                      color: const Color(0xFF1E40AF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.borderCircular,
                ),
                child: Text(
                  relative,
                  style: AppTypography.bodySmall().copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            notice.holidayName,
            style: AppTypography.titleMedium().copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Two announcement drafts are ready. Decide whether college is closed or open.',
            style: AppTypography.bodySmall().copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final targetId =
                    notice.holidayId > 0 ? notice.holidayId : notice.id;
                context.push(
                  targetId > 0
                      ? '/admin/holiday-notices/$targetId'
                      : '/admin/holiday-notices/pending',
                  extra: notice,
                );
              },
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Review & Decide'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.borderSm,
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
