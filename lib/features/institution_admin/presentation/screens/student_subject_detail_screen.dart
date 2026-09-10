import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bridge_mobile/features/institution_admin/data/models/class_detail_model.dart';
import 'package:bridge_mobile/features/institution_admin/presentation/controllers/role_academic_providers.dart';
import 'subject_members_screen.dart';

class StudentSubjectDetailScreen extends ConsumerStatefulWidget {
  final int subjectId;
  final String subjectName;
  final String teacherName;
  final int studentsCount;
  final bool showBottomNav;

  const StudentSubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.teacherName = '',
    this.studentsCount = 0,
    this.showBottomNav = false,
  });

  @override
  ConsumerState<StudentSubjectDetailScreen> createState() =>
      _StudentSubjectDetailScreenState();
}

class _StudentSubjectDetailScreenState
    extends ConsumerState<StudentSubjectDetailScreen> {
  String _selectedDoubtFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(subjectDetailsProvider(widget.subjectId));

    final dynamicStudentsCount = detailsAsync.when(
      data: (ClassDetailModel? details) => details?.totalStudents ?? widget.studentsCount,
      loading: () => widget.studentsCount,
      error: (_, __) => widget.studentsCount,
    );

    final dynamicTeacherName = detailsAsync.when(
      data: (ClassDetailModel? details) {
        if (details != null && details.classTeacherName != null && details.classTeacherName!.isNotEmpty) {
          return details.classTeacherName!;
        }
        return widget.teacherName.isNotEmpty ? widget.teacherName : 'Unassigned';
      },
      loading: () => widget.teacherName.isNotEmpty ? widget.teacherName : 'Loading...',
      error: (_, __) => 'Unassigned',
    );

    final hasAssignedTeacher = detailsAsync.when(
      data: (ClassDetailModel? details) => details?.classTeacherId != null,
      loading: () => false,
      error: (_, __) => false,
    );

    final displaySubjectName =
        widget.subjectName.isNotEmpty ? widget.subjectName : 'Untitled Subject';

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
              displaySubjectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              dynamicTeacherName,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
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
              const PopupMenuItem(value: 'share', child: Text('Share Subject')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Top 4 Metric Cards Grid (2x2) ──────────────────────────────
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
                  value: '$dynamicStudentsCount',
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
                  value: '128',
                  label: 'Discussions',
                ),
                _buildStatCard(
                  icon: Icons.access_time,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFF59E0B),
                  value: '26',
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
                  icon: Icons.help_outline,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  title: 'Ask Doubt',
                  onTap: () {},
                ),
                _buildQuickActionCard(
                  icon: Icons.chat_bubble_outline,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  title: 'View Doubts',
                  onTap: () {},
                ),
                _buildQuickActionCard(
                  icon: Icons.campaign_outlined,
                  iconBg: const Color(0xFFFEF2F2),
                  iconColor: const Color(0xFFDC2626),
                  title: 'Notices',
                  onTap: () {},
                ),
                _buildQuickActionCard(
                  icon: Icons.people_outline,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  title: 'Members',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectMembersScreen(
                          subjectId: widget.subjectId,
                          subjectName: displaySubjectName,
                          teacherName: dynamicTeacherName,
                          totalStudents: dynamicStudentsCount,
                          viewMode: ClassMembersViewMode.student,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 3. Latest Teacher Announcement ─────────────────────────────────
            const Text(
              'Latest Teacher Announcement',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mid-term exam on Monday',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dynamicTeacherName  •  Yesterday',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

            // Doubts Cards
            _buildDoubtCard(
              title: 'What is Third Normal Form?',
              author: 'Aarav',
              badgeText: '✓ Verified Answer',
              badgeBg: const Color(0xFFDCFCE7),
              badgeTextColor: const Color(0xFF15803D),
              repliesCount: '8',
              likesCount: '21',
            ),
            const SizedBox(height: 10),
            _buildDoubtCard(
              title: 'Explain BCNF',
              author: 'Sita',
              badgeText: '🕒 Waiting for Teacher',
              badgeBg: const Color(0xFFFFEDD5),
              badgeTextColor: const Color(0xFFC2410C),
              repliesCount: '4',
            ),
            const SizedBox(height: 10),
            _buildDoubtCard(
              title: 'Difference between 2NF and 3NF',
              author: 'Ram',
              badgeText: '👥 Community Discussion',
              badgeBg: const Color(0xFFDBEAFE),
              badgeTextColor: const Color(0xFF1D4ED8),
            ),
            const SizedBox(height: 24),
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

  Widget _buildDoubtCard({
    required String title,
    required String author,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
    String? repliesCount,
    String? likesCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            author,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          if (repliesCount != null || likesCount != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (repliesCount != null) ...[
                  const Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    '$repliesCount Replies',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
                if (likesCount != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    '$likesCount Likes',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}