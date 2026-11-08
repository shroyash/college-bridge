import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/helpers/nepal_time_helper.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/holiday_notice_draft.dart';
import '../../domain/entities/holiday_notice_enums.dart';
import '../../domain/entities/institution_holiday_notice.dart';
import '../../domain/entities/pending_holiday_notice.dart';
import '../controllers/holiday_notice_providers.dart';
import '../controllers/notice_detail_state.dart';
import '../widgets/audience_chips.dart';
import '../widgets/draft_card.dart';
import '../widgets/holiday_date_header.dart';
import '../widgets/notice_status_banner.dart';

class ReviewNoticeScreen extends ConsumerStatefulWidget {
  final int noticeId;
  final PendingHolidayNotice? initialPending;

  const ReviewNoticeScreen({
    super.key,
    required this.noticeId,
    this.initialPending,
  });

  @override
  ConsumerState<ReviewNoticeScreen> createState() => _ReviewNoticeScreenState();
}

class _ReviewNoticeScreenState extends ConsumerState<ReviewNoticeScreen> {
  NoticeVariant? _selectedVariant;
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  bool _isEditing = false;
  bool _notifyStudents = true;
  bool _notifyTeachers = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onSelectDraft(HolidayNoticeDraft draft) {
    setState(() {
      _selectedVariant = draft.variant;
      _titleController.text = draft.title;
      _bodyController.text = draft.body;
      _isEditing = true;
    });
  }

  void _onResetToProposal(PendingHolidayNotice pending) {
    if (_selectedVariant == null) return;
    final original = _selectedVariant == NoticeVariant.CLOSED
        ? pending.closedDraft
        : pending.openDraft;

    setState(() {
      _titleController.text = original.title;
      _bodyController.text = original.body;
    });
  }

  bool _isFormValid() {
    if (_selectedVariant == null) return false;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || title.length > 255) return false;
    if (body.isEmpty || body.length > 2000) return false;
    if (!_notifyStudents && !_notifyTeachers) return false;

    return true;
  }

  Future<void> _handleApprove(int id) async {
    if (!_isFormValid()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish Announcement?'),
        content: Text(
          'This will publish the notice to your '
          '${_notifyStudents && _notifyTeachers ? 'students and teachers' : _notifyStudents ? 'students' : 'teachers'} '
          'now. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve & Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final notifier = ref.read(
      noticeDetailNotifierProvider((
        noticeId: id,
        initialPending: widget.initialPending,
      )).notifier,
    );

    final success = await notifier.approve(
      variant: _selectedVariant!,
      customTitle: _titleController.text.trim(),
      customBody: _bodyController.text.trim(),
      notifyStudents: _notifyStudents,
      notifyTeachers: _notifyTeachers,
    );

    if (success && mounted) {
      SnackBarHelper.showSuccess(
        context,
        'Notice approved. Notifications are on their way.',
      );
      // Refresh pending list
      ref.read(pendingNoticeNotifierProvider.notifier).fetchPendingNotice();
    }
  }

  Future<void> _handleReject(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Don\'t Announce Holiday?'),
        content: const Text(
          'Are you sure you do not want to publish an announcement for this holiday? '
          'Students and teachers will not receive any notification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Don\'t Announce'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final notifier = ref.read(
      noticeDetailNotifierProvider((
        noticeId: id,
        initialPending: widget.initialPending,
      )).notifier,
    );

    final success = await notifier.reject();
    if (success && mounted) {
      SnackBarHelper.showSuccess(context, 'You chose not to announce this holiday.');
      ref.read(pendingNoticeNotifierProvider.notifier).fetchPendingNotice();
    }
  }

  void _showConflictDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Notice Already Decided'),
          ],
        ),
        content: Text(
          message.isNotEmpty
              ? message
              : 'Another administrator already decided this notice.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('View Latest State'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveId = widget.noticeId > 0 ? widget.noticeId : (widget.initialPending?.id ?? 0);

    ref.listen(
      noticeDetailNotifierProvider((
        noticeId: effectiveId,
        initialPending: widget.initialPending,
      )),
      (previous, next) {
        if (next is NoticeDetailConflict) {
          _showConflictDialog(next.message);
        }
      },
    );

    final state = ref.watch(
      noticeDetailNotifierProvider((
        noticeId: effectiveId,
        initialPending: widget.initialPending,
      )),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Holiday Notice',
          style: AppTypography.titleLarge().copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: switch (state) {
        NoticeDetailLoading() => const Center(child: AppLoading()),
        NoticeDetailError(:final message) => AppErrorState(
            message: message,
            onRetry: () {
              ref
                  .read(noticeDetailNotifierProvider((
                    noticeId: effectiveId,
                    initialPending: widget.initialPending,
                  )).notifier)
                  .loadNotice();
            },
          ),
        NoticeDetailConflict() => const Center(child: AppLoading()),
        NoticeDetailLoaded(:final notice, :final pendingNotice, :final isSubmitting) =>
          // If we have a decided notice, show Decided State (A3). Otherwise show Review & Approve (A2).
          (notice != null && notice.status.isDecided)
              ? _buildDecidedView(context, notice)
              : _buildReviewAndApproveView(
                  context,
                  pendingNotice ?? _synthesizePendingFromNotice(notice!),
                  effectiveId,
                  isSubmitting,
                ),
      },
    );
  }

  PendingHolidayNotice _synthesizePendingFromNotice(InstitutionHolidayNotice notice) {
    return PendingHolidayNotice(
      id: notice.id,
      institutionId: notice.institutionId,
      status: notice.status,
      holidayId: notice.holidayId,
      holidayDateAd: notice.holidayDateAd,
      holidayDateBs: notice.holidayDateBs,
      holidayName: notice.holidayName,
      closedDraft: HolidayNoticeDraft(
        variant: NoticeVariant.CLOSED,
        title: notice.finalTitle ?? 'College Closed for ${notice.holidayName}',
        body: notice.finalBody ?? 'College operations will remain closed for the holiday.',
      ),
      openDraft: HolidayNoticeDraft(
        variant: NoticeVariant.OPEN,
        title: notice.finalTitle ?? 'College Operations as Usual',
        body: notice.finalBody ?? 'Lectures and administration continue as scheduled.',
      ),
    );
  }

  /// Screen A2: Review & Approve
  Widget _buildReviewAndApproveView(
    BuildContext context,
    PendingHolidayNotice pending,
    int noticeId,
    bool isSubmitting,
  ) {
    final titleLength = _titleController.text.length;
    final bodyLength = _bodyController.text.length;
    final isPassed = NepalTimeHelper.relativeLabel(pending.holidayDateAd) == 'Passed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HolidayDateHeader(
            dateAd: pending.holidayDateAd,
            dateBs: pending.holidayDateBs,
            holidayName: pending.holidayName,
            scope: pending.holidayScope,
          ),
          const SizedBox(height: AppSpacing.md),

          // Helper callout
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'The app proposes two notices. Pick the one that matches your college. '
                    'Nothing is sent until you approve.',
                    style: AppTypography.bodyMedium().copyWith(
                      color: AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Two selectable draft cards
          DraftCard(
            draft: pending.closedDraft,
            isSelected: _selectedVariant == NoticeVariant.CLOSED,
            onSelect: () => _onSelectDraft(pending.closedDraft),
          ),
          const SizedBox(height: AppSpacing.sm),
          DraftCard(
            draft: pending.openDraft,
            isSelected: _selectedVariant == NoticeVariant.OPEN,
            onSelect: () => _onSelectDraft(pending.openDraft),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Expandable editing section when a proposal is selected
          if (_isEditing && _selectedVariant != null) ...[
            Container(
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
                      Text(
                        'Customize Announcement',
                        style: AppTypography.titleMedium().copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _onResetToProposal(pending),
                        icon: const Icon(Icons.restore_rounded, size: 16),
                        label: const Text('Reset to proposal'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Title field
                  TextField(
                    controller: _titleController,
                    maxLength: 255,
                    enabled: !isSubmitting,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Notice Title',
                      counterText: '$titleLength/255',
                      border: const OutlineInputBorder(
                        borderRadius: AppRadius.borderSm,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: AppRadius.borderSm,
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Body field
                  TextField(
                    controller: _bodyController,
                    maxLength: 2000,
                    maxLines: 6,
                    enabled: !isSubmitting,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Notice Body (English & Nepali)',
                      alignLabelWithHint: true,
                      counterText: '$bodyLength/2000',
                      border: const OutlineInputBorder(
                        borderRadius: AppRadius.borderSm,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: AppRadius.borderSm,
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Audience filter chips
            AudienceChips(
              notifyStudents: _notifyStudents,
              notifyTeachers: _notifyTeachers,
              onStudentsChanged: (val) => setState(() => _notifyStudents = val),
              onTeachersChanged: (val) => setState(() => _notifyTeachers = val),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          if (isPassed) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: AppRadius.borderSm,
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.event_busy_rounded, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The calendar date for this holiday has already passed. Approval is disabled.',
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Primary approve button
          PrimaryButton(
            text: 'Approve and Publish',
            icon: Icons.check_circle_outline_rounded,
            isLoading: isSubmitting,
            onPressed: (_isFormValid() && !isPassed)
                ? () => _handleApprove(noticeId)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Secondary reject button
          Center(
            child: TextButton(
              onPressed: (!isSubmitting && !isPassed)
                  ? () => _handleReject(noticeId)
                  : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondaryLight,
              ),
              child: const Text('Don\'t announce (Skip this holiday)'),
            ),
          ),
        ],
      ),
    );
  }

  /// Screen A3: Decided State (Read-Only)
  Widget _buildDecidedView(BuildContext context, InstitutionHolidayNotice notice) {
    final formattedDate = NepalTimeHelper.formatReadableDate(notice.holidayDateAd);
    final publishedNpt = notice.publishedAt != null
        ? NepalTimeHelper.formatNepalDateTime(notice.publishedAt!)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NoticeStatusBanner(
            status: notice.status,
            publishedAtNpt: publishedNpt,
          ),
          const SizedBox(height: AppSpacing.md),

          // Holiday details card
          Container(
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
                    Text(
                      notice.holidayName,
                      style: AppTypography.titleLarge().copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    if (notice.variant != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: notice.variant == NoticeVariant.CLOSED
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFECFDF5),
                          borderRadius: AppRadius.borderCircular,
                        ),
                        child: Text(
                          notice.variant!.badgeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: notice.variant == NoticeVariant.CLOSED
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$formattedDate · ${notice.holidayDateBs} BS',
                  style: AppTypography.bodyMedium().copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const Divider(height: 24),

                Text(
                  notice.finalTitle ?? 'Official Notice',
                  style: AppTypography.titleMedium().copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  notice.finalBody ?? 'No details provided.',
                  style: AppTypography.bodyMedium().copyWith(
                    color: AppColors.textSecondaryLight,
                    height: 1.5,
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
