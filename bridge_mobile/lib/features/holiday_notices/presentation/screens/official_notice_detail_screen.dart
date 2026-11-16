import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/helpers/nepal_time_helper.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../domain/entities/holiday_notice_enums.dart';
import '../../domain/entities/official_holiday_notice.dart';

class OfficialNoticeDetailScreen extends StatelessWidget {
  final OfficialHolidayNotice notice;

  const OfficialNoticeDetailScreen({
    super.key,
    required this.notice,
  });

  @override
  Widget build(BuildContext context) {
    final isClosed = notice.variant == NoticeVariant.CLOSED;
    final formattedDate = NepalTimeHelper.formatReadableDate(notice.dateAd);
    final publishedNpt = notice.publishedAt != null
        ? NepalTimeHelper.formatNepalDateTime(notice.publishedAt!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notice Details',
          style: AppTypography.titleLarge().copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy notice',
            icon: const Icon(Icons.copy_rounded, color: AppColors.textPrimaryLight),
            onPressed: () {
              final copyText = '${notice.title}\n\n${notice.body}';
              Clipboard.setData(ClipboardData(text: copyText));
              SnackBarHelper.showSuccess(context, 'Notice text copied to clipboard.');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and variant banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isClosed ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
                borderRadius: AppRadius.borderMd,
                border: Border.all(
                  color: isClosed ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isClosed ? Icons.cancel_outlined : Icons.check_circle_outline,
                    color: isClosed ? AppColors.error : AppColors.success,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isClosed ? 'COLLEGE CLOSED' : 'COLLEGE OPEN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isClosed ? AppColors.error : AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Official announcement for ${notice.holidayName}',
                          style: AppTypography.bodySmall().copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Main document container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dates header
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '$formattedDate · ${notice.dateBs} BS',
                        style: AppTypography.bodyMedium().copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notice Title
                  Text(
                    notice.title,
                    style: AppTypography.displayLarge().copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // Notice Body
                  Text(
                    notice.body,
                    style: AppTypography.bodyLarge().copyWith(
                      color: AppColors.textSecondaryLight,
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Footer timestamp
                  if (publishedNpt != null) ...[
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Verified college announcement · $publishedNpt',
                          style: AppTypography.bodySmall().copyWith(
                            color: AppColors.textMutedLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
