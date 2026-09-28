import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bridge_mobile/features/dashboard/presentation/controllers/dashboard_providers.dart';
import 'package:bridge_mobile/features/dashboard/presentation/controllers/dashboard_state.dart';
import 'package:bridge_mobile/features/dashboard/domain/entities/subject.dart';
import '../controllers/doubt_providers.dart';
import '../../data/models/doubt_model.dart';
import '../../data/models/doubt_summary_model.dart';
import '../widgets/ask_doubt_dialog.dart';
import 'doubt_detail_screen.dart';

class StudentDoubtsScreen extends ConsumerStatefulWidget {
  final int? initialSubjectId;

  const StudentDoubtsScreen({
    super.key,
    this.initialSubjectId,
  });

  @override
  ConsumerState<StudentDoubtsScreen> createState() => _StudentDoubtsScreenState();
}

class _StudentDoubtsScreenState extends ConsumerState<StudentDoubtsScreen> {
  final _searchController = TextEditingController();
  int? _selectedSubjectId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAskDoubtDialog([int? subjectId, String? subjectName]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AskDoubtDialog(
        initialSubjectId: subjectId ?? _selectedSubjectId,
        initialSubjectName: subjectName,
      ),
    );

    if (result == true) {
      ref.invalidate(doubtsListProvider);
      ref.invalidate(subjectDoubtSummaryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(studentDashboardNotifierProvider);

    List<Subject> enrolledSubjects = [];
    if (dashboardState is DashboardSuccess<List<Subject>>) {
      enrolledSubjects = dashboardState.data;
    }

    final queryArg = (subjectId: _selectedSubjectId, search: _searchQuery.isEmpty ? null : _searchQuery);
    final doubtsAsync = ref.watch(doubtsListProvider(queryArg));
    final summaryAsync = ref.watch(subjectDoubtSummaryProvider(_selectedSubjectId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Doubts & Peer Learning',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
            onPressed: () {
              ref.invalidate(doubtsListProvider);
              ref.invalidate(subjectDoubtSummaryProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAskDoubtDialog(),
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text(
          'Ask Doubt',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(doubtsListProvider);
          ref.invalidate(subjectDoubtSummaryProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doubt Summary Statistics Widget
                    _buildSummaryCard(summaryAsync),
                    const SizedBox(height: 16),

                    // Search & Filter controls
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() => _searchQuery = val.trim());
                            },
                            decoration: InputDecoration(
                              hintText: 'Search doubts...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (enrolledSubjects.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('All Subjects'),
                                selected: _selectedSubjectId == null,
                                selectedColor: const Color(0xFFDBEAFE),
                                checkmarkColor: const Color(0xFF2563EB),
                                labelStyle: TextStyle(
                                  color: _selectedSubjectId == null
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFF475569),
                                  fontWeight: _selectedSubjectId == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedSubjectId = null);
                                  }
                                },
                              ),
                            ),
                            ...enrolledSubjects.map((sub) {
                              final isSelected = _selectedSubjectId == sub.subjectId;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(sub.name),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFFDBEAFE),
                                  checkmarkColor: const Color(0xFF2563EB),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFF475569),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedSubjectId = selected ? sub.subjectId : null;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Doubts List Section
            doubtsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load doubts: ${err.toString()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(doubtsListProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (doubts) {
                if (doubts.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No doubts found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Have a question? Ask your peers and teachers!',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _openAskDoubtDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Ask a Doubt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doubt = doubts[index];
                        return _buildDoubtCard(context, doubt);
                      },
                      childCount: doubts.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AsyncValue<DoubtSummaryModel> summaryAsync) {
    return summaryAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
            ),
            SizedBox(width: 12),
            Text('Loading doubt statistics...', style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Doubts', '${summary.total}', Icons.forum_outlined, Colors.white),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem('Solved', '${summary.solved}', Icons.check_circle_outline, const Color(0xFF4ADE80)),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem('Unsolved', '${summary.unsolved}', Icons.pending_outlined, const Color(0xFFFDE047)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildDoubtCard(BuildContext context, DoubtModel doubt) {
    final isSolved = doubt.status == 'RESOLVED' || doubt.status == 'ANSWERED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoubtDetailScreen(doubtId: doubt.doubtId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Subject & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doubt.subjectName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSolved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doubt.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSolved ? const Color(0xFF15803D) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Question Text
                Text(
                  doubt.question,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // Footer: Student Name, Answer Count, Helpful Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFFDBEAFE),
                          child: Text(
                            doubt.studentName.isNotEmpty
                                ? doubt.studentName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          doubt.studentName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(
                              doubt.helpful ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                              size: 15,
                              color: doubt.helpful ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              doubt.helpful ? 'Helpful' : 'Vote',
                              style: TextStyle(
                                fontSize: 12,
                                color: doubt.helpful ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                fontWeight: doubt.helpful ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 15, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              '${doubt.answerCount}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
