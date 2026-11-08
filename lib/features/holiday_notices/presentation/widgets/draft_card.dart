import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/holiday_notice_draft.dart';
import '../../domain/entities/holiday_notice_enums.dart';

class DraftCard extends StatelessWidget {
  final HolidayNoticeDraft draft;
  final bool isSelected;
  final VoidCallback onSelect;

  const DraftCard({
    super.key,
    required this.draft,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isClosed = draft.variant == NoticeVariant.CLOSED;
    final isAi = draft.origin == NoticeOrigin.AI;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${draft.variant.label}: ${draft.title}',
      child: InkWell(
        onTap: onSelect,
        borderRadius: AppRadius.borderMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF5F7FF) : AppColors.surfaceLight,
            borderRadius: AppRadius.borderMd,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected ? AppShadows.md : AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected ? AppColors.primary : AppColors.textMutedLight,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        isClosed ? 'Option A: College Closed' : 'Option B: College Open',
                        style: AppTypography.titleMedium().copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isAi ? const Color(0xFFEDE9FE) : const Color(0xFFF1F5F9),
                      borderRadius: AppRadius.borderCircular,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAi ? Icons.auto_awesome : Icons.description_outlined,
                          size: 12,
                          color: isAi ? const Color(0xFF7C3AED) : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAi ? 'AI Draft' : 'Standard',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isAi ? const Color(0xFF7C3AED) : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                draft.title,
                style: AppTypography.bodyLarge().copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                draft.body,
                maxLines: isSelected ? 8 : 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium().copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
