import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

class AudienceChips extends StatelessWidget {
  final bool notifyStudents;
  final bool notifyTeachers;
  final ValueChanged<bool> onStudentsChanged;
  final ValueChanged<bool> onTeachersChanged;

  const AudienceChips({
    super.key,
    required this.notifyStudents,
    required this.notifyTeachers,
    required this.onStudentsChanged,
    required this.onTeachersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.group_outlined, size: 18, color: AppColors.textSecondaryLight),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Publish & notify audience:',
              style: AppTypography.labelLarge().copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            FilterChip(
              label: const Text('Students'),
              selected: notifyStudents,
              avatar: Icon(
                notifyStudents ? Icons.check_circle_rounded : Icons.school_outlined,
                size: 16,
                color: notifyStudents ? Colors.white : AppColors.textSecondaryLight,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
              labelStyle: TextStyle(
                color: notifyStudents ? Colors.white : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderCircular,
                side: BorderSide(
                  color: notifyStudents ? AppColors.primary : AppColors.borderLight,
                ),
              ),
              onSelected: (bool selected) {
                // Rule: at least one audience must stay selected
                if (!selected && !notifyTeachers) {
                  return;
                }
                onStudentsChanged(selected);
              },
            ),
            FilterChip(
              label: const Text('Teachers'),
              selected: notifyTeachers,
              avatar: Icon(
                notifyTeachers ? Icons.check_circle_rounded : Icons.person_outline,
                size: 16,
                color: notifyTeachers ? Colors.white : AppColors.textSecondaryLight,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
              labelStyle: TextStyle(
                color: notifyTeachers ? Colors.white : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderCircular,
                side: BorderSide(
                  color: notifyTeachers ? AppColors.primary : AppColors.borderLight,
                ),
              ),
              onSelected: (bool selected) {
                // Rule: at least one audience must stay selected
                if (!selected && !notifyStudents) {
                  return;
                }
                onTeachersChanged(selected);
              },
            ),
          ],
        ),
      ],
    );
  }
}
