import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bridge_mobile/features/institution_admin/data/models/class_detail_model.dart';
import 'package:bridge_mobile/features/institution_admin/presentation/controllers/role_academic_providers.dart';
import 'subject_members_screen.dart';
import 'package:bridge_mobile/features/doubt/presentation/controllers/doubt_providers.dart';
import 'package:bridge_mobile/features/doubt/presentation/widgets/subject_doubts_view.dart';

class TeacherClassDetailScreen extends ConsumerStatefulWidget {
  final int classId;
  final String className;

  const TeacherClassDetailScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  ConsumerState<TeacherClassDetailScreen> createState() =>
      _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState
    extends ConsumerState<TeacherClassDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayClassName =
        widget.className.isNotEmpty ? widget.className : 'Untitled Class';

    final detailsAsync = ref.watch(subjectDetailsProvider(widget.classId));
    final doubtSummaryAsync = ref.watch(subjectDoubtSummaryProvider(widget.classId));

    final dynamicStudentsCount = detailsAsync.when(
      data: (ClassDetailModel? d) => d?.totalStudents ?? 0,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final dynamicTeacherName = detailsAsync.when(
      data: (ClassDetailModel? d) =>
          (d?.classTeacherName?.isNotEmpty == true) ? d!.classTeacherName! : 'Assigned Teacher',
      loading: () => 'Assigned Teacher',
      error: (_, __) => 'Assigned Teacher',
    );

    final hasAssignedTeacher = detailsAsync.when(
      data: (ClassDetailModel? d) => d?.classTeacherId != null,
      loading: () => false,
      error: (_, __) => false,
    );

    final totalDoubtsText = doubtSummaryAsync.when(
      data: (summary) => '${summary.total}',
      loading: () => '...',
      error: (_, __) => '0',
    );

    final unsolvedDoubtsText = doubtSummaryAsync.when(
      data: (summary) => '${summary.unsolved}',
      loading: () => '...',
      error: (_, __) => '0',
    );

    final dynamicSubtitle = detailsAsync.when(
      data: (ClassDetailModel? d) {
        if (d == null) return 'Loading...';
        final parts = <String>[];
        if (d.programName.isNotEmpty) parts.add(d.programName);
        if (d.levelName.isNotEmpty) parts.add(d.levelName);
        return parts.isNotEmpty ? parts.join(' • ') : displayClassName;
      },
      loading: () => 'Loading class info...',
      error: (_, __) => displayClassName,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2563EB), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayClassName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              dynamicSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
            onPressed: () {
              ref.invalidate(subjectDetailsProvider(widget.classId));
              ref.invalidate(subjectDoubtSummaryProvider(widget.classId));
              ref.invalidate(doubtsListProvider);
            },
          ),
        ],
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildErrorState(e.toString()),
        data: (details) => _buildBody(
          context,
          details,
          displayClassName,
          dynamicStudentsCount,
          dynamicTeacherName,
          hasAssignedTeacher,
          totalDoubtsText,
          unsolvedDoubtsText,
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(subjectDetailsProvider(widget.classId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ClassDetailModel? details,
    String displayClassName,
    int studentsCount,
    String teacherName,
    bool hasAssignedTeacher,
    String totalDoubtsText,
    String unsolvedDoubtsText,
  ) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Stats Grid (2x2) ──────────────────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _buildStatCard(
                icon: Icons.groups_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                value: '$studentsCount',
                label: 'Students',
              ),
              _buildStatCard(
                icon: Icons.school_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                value: hasAssignedTeacher ? '1' : '0',
                label: 'Assigned Teacher',
              ),
              _buildStatCard(
                icon: Icons.chat_bubble_outline,
                iconBg: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF10B981),
                value: totalDoubtsText,
                label: 'Total Doubts',
              ),
              _buildStatCard(
                icon: Icons.access_time,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFF59E0B),
                value: unsolvedDoubtsText,
                label: 'Unresolved',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 2. QUICK ACTIONS (2x2) ─────────────────────────────────────────
          const Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _buildQuickActionCard(
                icon: Icons.question_answer_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Solve Doubts',
                onTap: () {
                  ref.invalidate(subjectDoubtSummaryProvider(widget.classId));
                  ref.invalidate(doubtsListProvider);
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
              _buildQuickActionCard(
                icon: Icons.find_in_page_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Review Doubts',
                onTap: () {
                  ref.invalidate(subjectDoubtSummaryProvider(widget.classId));
                  ref.invalidate(doubtsListProvider);
                },
              ),
              _buildQuickActionCard(
                icon: Icons.campaign_outlined,
                iconBg: const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFDC2626),
                title: 'Post Notice',
                onTap: () {},
              ),
              _buildQuickActionCard(
                icon: Icons.groups_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Class Students',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectMembersScreen(
                        subjectId: widget.classId,
                        subjectName: displayClassName,
                        teacherName: teacherName,
                        totalStudents: studentsCount,
                        viewMode: ClassMembersViewMode.teacher,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 3. Doubts Section ─────────────────────────────────────────────
          SubjectDoubtsView(
            subjectId: widget.classId,
            subjectName: displayClassName,
            isTeacher: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }



  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}