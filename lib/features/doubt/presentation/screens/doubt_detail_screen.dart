import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bridge_mobile/core/storage/secure_storage_service.dart';
import '../controllers/doubt_providers.dart';
import '../../data/models/doubt_model.dart';
import '../../data/models/doubt_answer_model.dart';

final _userRoleProvider = FutureProvider.autoDispose<String>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return await storage.getUserRole() ?? 'STUDENT';
});

class DoubtDetailScreen extends ConsumerStatefulWidget {
  final int doubtId;

  const DoubtDetailScreen({
    super.key,
    required this.doubtId,
  });

  @override
  ConsumerState<DoubtDetailScreen> createState() => _DoubtDetailScreenState();
}

class _DoubtDetailScreenState extends ConsumerState<DoubtDetailScreen> {
  final _answerController = TextEditingController();
  bool _isSubmittingAnswer = false;
  int? _verifyingAnswerId;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    final text = _answerController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an answer'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmittingAnswer = true);

    try {
      final ds = ref.read(doubtRemoteDataSourceProvider);
      await ds.answerDoubt(
        doubtId: widget.doubtId,
        answer: text,
      );

      _answerController.clear();
      ref.invalidate(doubtDetailProvider(widget.doubtId));
      ref.invalidate(doubtsListProvider);
      ref.invalidate(subjectDoubtSummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer posted successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post answer: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingAnswer = false);
    }
  }

  Future<void> _verifyAnswer(int answerId) async {
    setState(() => _verifyingAnswerId = answerId);

    try {
      final ds = ref.read(doubtRemoteDataSourceProvider);
      await ds.verifyAnswer(answerId);

      ref.invalidate(doubtDetailProvider(widget.doubtId));
      ref.invalidate(doubtsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer verified successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify answer: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _verifyingAnswerId = null);
    }
  }

  Future<void> _toggleHelpful(bool currentHelpful) async {
    try {
      final ds = ref.read(doubtRemoteDataSourceProvider);
      await ds.markHelpful(widget.doubtId);
      ref.invalidate(doubtDetailProvider(widget.doubtId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update helpful status: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doubtAsync = ref.watch(doubtDetailProvider(widget.doubtId));
    final roleAsync = ref.watch(_userRoleProvider);

    final userRole = roleAsync.when(
      data: (role) => role.toUpperCase(),
      loading: () => 'STUDENT',
      error: (_, __) => 'STUDENT',
    );
    final isTeacher = userRole == 'TEACHER';
    final isAdmin = userRole == 'ADMIN';
    final isStudent = userRole == 'STUDENT';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2563EB), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Doubt Thread',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
            onPressed: () => ref.invalidate(doubtDetailProvider(widget.doubtId)),
          ),
        ],
      ),
      body: doubtAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 12),
                Text(
                  'Failed to load doubt: ${e.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(doubtDetailProvider(widget.doubtId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (DoubtModel doubt) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doubt Header Card
                      _buildDoubtHeaderCard(doubt, isStudent: isStudent),
                      const SizedBox(height: 24),

                      // Answers Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ANSWERS (${doubt.answers.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (doubt.verifiedAnswerCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '✓ ${doubt.verifiedAnswerCount} Verified',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Empty Answers state
                      if (doubt.answers.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.chat_bubble_outline,
                                  color: Color(0xFF94A3B8), size: 40),
                              const SizedBox(height: 12),
                              const Text(
                                'No answers yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAdmin
                                    ? 'No answers have been posted for this doubt.'
                                    : 'Be the first to help with this doubt.',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: doubt.answers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final answer = doubt.answers[index];
                            return _buildAnswerCard(answer, isTeacher);
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Answer Input Bar at Bottom (Hidden for Admin)
              if (!isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _answerController,
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: isTeacher
                                  ? 'Write a verified teacher answer...'
                                  : 'Write an answer...',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _isSubmittingAnswer ? null : _submitAnswer,
                          icon: _isSubmittingAnswer
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDoubtHeaderCard(DoubtModel doubt, {bool isStudent = true}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  doubt.subjectName,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              _buildStatusBadge(doubt.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            doubt.question,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFDBEAFE),
                    child: Text(
                      doubt.studentName.isNotEmpty
                          ? doubt.studentName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    doubt.studentName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: isStudent ? () => _toggleHelpful(doubt.helpful) : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Icon(
                        doubt.helpful
                            ? Icons.thumb_up
                            : Icons.thumb_up_alt_outlined,
                        size: 16,
                        color: isStudent && doubt.helpful
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        doubt.helpful ? 'Helpful' : 'Mark Helpful',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isStudent && doubt.helpful
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFEFF6FF);
    Color text = const Color(0xFF2563EB);
    String label = status.toUpperCase();

    if (status.toUpperCase() == 'ANSWERED') {
      bg = const Color(0xFFECFDF5);
      text = const Color(0xFF059669);
      label = 'ANSWERED';
    } else if (status.toUpperCase() == 'RESOLVED') {
      bg = const Color(0xFFF0FDF4);
      text = const Color(0xFF16A34A);
      label = 'RESOLVED';
    } else if (status.toUpperCase() == 'OPEN') {
      bg = const Color(0xFFFFF7ED);
      text = const Color(0xFFD97706);
      label = 'OPEN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  Widget _buildAnswerCard(DoubtAnswerModel answer, bool isTeacherUser) {
    final isVerifyingThis = _verifyingAnswerId == answer.answerId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: answer.verified
              ? const Color(0xFF86EFAC)
              : const Color(0xFFE2E8F0),
          width: answer.verified ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: answer.answeredByTeacher
                        ? const Color(0xFFDBEAFE)
                        : const Color(0xFFF1F5F9),
                    child: Icon(
                      answer.answeredByTeacher
                          ? Icons.school
                          : Icons.person_outline,
                      size: 14,
                      color: answer.answeredByTeacher
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer.answeredByName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (answer.answeredByTeacher)
                        const Text(
                          'Teacher',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // Verified Badge or Action
              if (answer.verified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF15803D), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        answer.answeredByTeacher
                            ? 'Verified Teacher Answer'
                            : 'Verified Answer',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                )
              else if (isTeacherUser)
                ElevatedButton.icon(
                  onPressed:
                      isVerifyingThis ? null : () => _verifyAnswer(answer.answerId),
                  icon: isVerifyingThis
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 14),
                  label: const Text(
                    'Verify Answer',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Not Verified',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            answer.answer,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
