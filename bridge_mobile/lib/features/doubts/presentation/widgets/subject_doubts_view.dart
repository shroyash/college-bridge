import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/doubt_providers.dart';
import '../../data/models/doubt_model.dart';
import '../../data/models/doubt_summary_model.dart';
import '../screens/doubt_detail_screen.dart';
import 'ask_doubt_dialog.dart';

class SubjectDoubtsView extends ConsumerWidget {
  final int subjectId;
  final String subjectName;
  final bool isTeacher;

  const SubjectDoubtsView({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.isTeacher = false,
  });

  Future<void> _openAskDoubtDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AskDoubtDialog(
        initialSubjectId: subjectId,
        initialSubjectName: subjectName,
      ),
    );

    if (result == true) {
      ref.invalidate(doubtsListProvider);
      ref.invalidate(subjectDoubtSummaryProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doubtsAsync = ref.watch(doubtsListProvider((subjectId: subjectId, search: null)));
    final summaryAsync = ref.watch(subjectDoubtSummaryProvider(subjectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Doubt Summary Header Box
        _buildSummaryHeader(summaryAsync),
        const SizedBox(height: 16),

        // Title and Ask Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Doubts & Discussions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            if (!isTeacher)
              TextButton.icon(
                onPressed: () => _openAskDoubtDialog(context, ref),
                icon: const Icon(Icons.add_comment, size: 18, color: Color(0xFF2563EB)),
                label: const Text(
                  'Ask Doubt',
                  style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Doubts List
        doubtsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to load doubts: ${err.toString()}',
                    style: const TextStyle(color: Color(0xFF991B1B)),
                  ),
                ),
              ],
            ),
          ),
          data: (doubts) {
            if (doubts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No doubts asked yet',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTeacher
                          ? 'Students in this class have not asked any doubts yet.'
                          : 'Be the first student to ask a doubt in this subject!',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                    if (!isTeacher) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openAskDoubtDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Ask a Doubt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: doubts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doubt = doubts[index];
                return _buildDoubtTile(context, doubt);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(AsyncValue<DoubtSummaryModel> summaryAsync) {
    return summaryAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric('Total Doubts', '${summary.total}', const Color(0xFF2563EB)),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              _buildStatMetric('Solved', '${summary.solved}', const Color(0xFF16A34A)),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              _buildStatMetric('Unsolved', '${summary.unsolved}', const Color(0xFFD97706)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildDoubtTile(BuildContext context, DoubtModel doubt) {
    final isSolved = doubt.status == 'RESOLVED' || doubt.status == 'ANSWERED';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoubtDetailScreen(doubtId: doubt.doubtId),
            ),
          );
        },
        title: Text(
          doubt.question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Text(
                'By ${doubt.studentName}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${doubt.answerCount}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSolved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            doubt.status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSolved ? const Color(0xFF15803D) : const Color(0xFFB45309),
            ),
          ),
        ),
      ),
    );
  }
}
