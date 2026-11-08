import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/helpers/nepal_time_helper.dart';

class HolidayDateHeader extends StatelessWidget {
  final String dateAd;
  final String dateBs;
  final String holidayName;
  final String? scope;

  const HolidayDateHeader({
    super.key,
    required this.dateAd,
    required this.dateBs,
    required this.holidayName,
    this.scope,
  });

  @override
  Widget build(BuildContext context) {
    final relative = NepalTimeHelper.relativeLabel(dateAd);
    final formattedDate = NepalTimeHelper.formatReadableDate(dateAd);

    final isTomorrowOrToday = relative == 'Tomorrow' || relative == 'Today';

    return Container(
      width: double.infinity,
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
                decoration: BoxDecoration(
                  color: isTomorrowOrToday ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                  borderRadius: AppRadius.borderCircular,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: 14,
                      color: isTomorrowOrToday ? AppColors.primary : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      relative,
                      style: AppTypography.labelMedium().copyWith(
                        color: isTomorrowOrToday ? AppColors.primary : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (scope != null && scope!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: AppRadius.borderCircular,
                  ),
                  child: Text(
                    scope!.toUpperCase(),
                    style: AppTypography.bodySmall().copyWith(
                      color: AppColors.textMutedLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            holidayName,
            style: AppTypography.titleLarge().copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                formattedDate,
                style: AppTypography.bodyMedium().copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (dateBs.isNotEmpty) ...[
                const Text(' · ', style: TextStyle(color: AppColors.textMutedLight)),
                Text(
                  '$dateBs BS',
                  style: AppTypography.bodyMedium().copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
