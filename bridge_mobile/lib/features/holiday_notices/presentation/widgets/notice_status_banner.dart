import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/holiday_notice_enums.dart';

class NoticeStatusBanner extends StatelessWidget {
  final NoticeStatus status;
  final String? publishedAtNpt;

  const NoticeStatusBanner({
    super.key,
    required this.status,
    this.publishedAtNpt,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    switch (status) {
      case NoticeStatus.APPROVED:
      case NoticeStatus.PUBLISHING:
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFFBFDBFE);
        textColor = const Color(0xFF1D4ED8);
        icon = Icons.hourglass_top_rounded;
        title = 'Approved. Sending notifications.';
        subtitle = 'The announcement is queued and push dispatches are underway.';
        break;

      case NoticeStatus.PUBLISHED:
        bgColor = AppColors.successLight;
        borderColor = const Color(0xFFA7F3D0);
        textColor = const Color(0xFF065F46);
        icon = Icons.check_circle_rounded;
        title = 'Approved and sent';
        subtitle = publishedAtNpt != null
            ? 'Broadcasted on $publishedAtNpt'
            : 'Push notifications delivered to selected campus members.';
        break;

      case NoticeStatus.FAILED:
        bgColor = AppColors.warningLight;
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFF92400E);
        icon = Icons.warning_amber_rounded;
        title = 'Delivery pending';
        subtitle =
            'The notice is official and visible in the app, but the push notification could not be delivered.';
        break;

      case NoticeStatus.REJECTED:
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFCBD5E1);
        textColor = const Color(0xFF334155);
        icon = Icons.block_rounded;
        title = 'Announcement declined';
        subtitle = 'You chose not to announce this holiday. Campus was not notified.';
        break;

      case NoticeStatus.EXPIRED:
        bgColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFE2E8F0);
        textColor = AppColors.textMutedLight;
        icon = Icons.schedule_rounded;
        title = 'Expired';
        subtitle = 'The date passed without an administrative decision.';
        break;

      case NoticeStatus.AWAITING_DECISION:
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFFB45309);
        icon = Icons.notification_important_rounded;
        title = 'Awaiting Decision';
        subtitle = 'Review drafts and publish your college notice.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge().copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall().copyWith(
                    color: textColor.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
