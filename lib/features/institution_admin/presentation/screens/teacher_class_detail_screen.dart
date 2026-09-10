import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bridge_mobile/features/institution_admin/data/models/class_detail_model.dart';
import 'package:bridge_mobile/features/institution_admin/presentation/controllers/role_academic_providers.dart';
import 'subject_members_screen.dart';

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
  String _selectedDoubtFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final displayClassName =
        widget.className.isNotEmpty ? widget.className : 'Untitled Class';

    final detailsAsync = ref.watch(subjectDetailsProvider(widget.classId));

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
            onSelected: (val) {},
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'refresh', child: Text('Refresh Data')),
              const PopupMenuItem(value: 'settings', child: Text('Class Settings')),
            ],
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
  ) {
    return SingleChildScrollView(
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
                value: '—',
                label: 'Discussions',
              ),
              _buildStatCard(
                icon: Icons.access_time,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFF59E0B),
                value: '—',
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
                onTap: () {},
              ),
              _buildQuickActionCard(
                icon: Icons.find_in_page_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Review Doubts',
                onTap: () {},
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
          const SizedBox(height: 20),

          // ── 3. Class Announcements ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Class Announcements',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  '+ Post Notice',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildEmptyAnnouncementsCard(),
          const SizedBox(height: 20),

          // ── 4. Recent Doubts ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Doubts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  _buildDoubtFilterChip('All', _selectedDoubtFilter == 'All', () {
                    setState(() => _selectedDoubtFilter = 'All');
                  }),
                  const SizedBox(width: 6),
                  _buildDoubtFilterChip('Unsolved', _selectedDoubtFilter == 'Unsolved', () {
                    setState(() => _selectedDoubtFilter = 'Unsolved');
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDoubtsComingSoonCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyAnnouncementsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No announcements yet. Tap + Post Notice to add one.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubtsComingSoonCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.question_answer_outlined, color: Color(0xFFCBD5E1), size: 36),
            SizedBox(height: 8),
            Text(
              'Doubts feature coming soon',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ],
        ),
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

  Widget _buildDoubtFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}