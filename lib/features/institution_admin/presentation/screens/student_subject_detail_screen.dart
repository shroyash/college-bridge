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
    required this.teacherName,
    this.studentsCount = 42,
    this.showBottomNav = false,
  });

  @override
  ConsumerState<StudentSubjectDetailScreen> createState() =>
      _StudentSubjectDetailScreenState();
}

class _StudentSubjectDetailScreenState
    extends ConsumerState<StudentSubjectDetailScreen> {
  int _selectedNavIndex = 1; // 1 = Subjects
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
        if (details != null) {
          if (details.classTeacherName != null && details.classTeacherName!.isNotEmpty) {
            return details.classTeacherName!;
          }
          if (details.teachers.isNotEmpty) {
            return details.teachers.first.fullName;
          }
          return 'Teacher not assigned';
        }
        return widget.teacherName.isNotEmpty ? widget.teacherName : 'Teacher not assigned';
      },
      loading: () => widget.teacherName.isNotEmpty ? widget.teacherName : 'Teacher not assigned',
      error: (_, __) => 'Teacher not assigned',
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
              widget.subjectName,
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
            onPressed: () => ref.invalidate(subjectDetailsProvider(widget.subjectId)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                  icon: Icons.description_outlined,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  value: '128',
                  label: 'Doubts',
                ),
                _buildStatCard(
                  icon: Icons.check_circle_outline,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  value: '102',
                  label: 'Solved',
                ),
                _buildStatCard(
                  icon: Icons.access_time,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  value: '26',
                  label: 'Open',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── 2. QUICK ACTIONS (2x2) ─────────────────────────────────────────
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _buildQuickActionCard(
                  icon: Icons.help_outline_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: 'Ask Doubt',
                ),
                _buildQuickActionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: 'View Doubts',
                ),
                _buildQuickActionCard(
                  icon: Icons.campaign_outlined,
                  iconColor: const Color(0xFFDC2626),
                  title: 'Notices',
                ),
                _buildQuickActionCard(
                  icon: Icons.people_outline_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: 'Members',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectMembersScreen(
                          subjectName: widget.subjectName,
                          teacherName: dynamicTeacherName,
                          totalStudents: dynamicStudentsCount,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── 3. Latest Teacher Announcement ─────────────────────────────────
            const Text(
              'Latest Teacher Announcement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
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
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign_outlined,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mid-term exam on Monday',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.teacherName}  •  Yesterday',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 4. Recent Doubts ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Doubts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Row(
                  children: [
                    _buildFilterPill('All'),
                    const SizedBox(width: 6),
                    _buildFilterPill('Unsolved'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Doubt Card 1
            if (_selectedDoubtFilter == 'All') ...[
              _buildDoubtCard(
                title: 'What is Third Normal Form?',
                badgeText: ' Verified Answer',
                badgeIcon: Icons.check_circle,
                badgeBg: const Color(0xFFDCFCE7),
                badgeColor: const Color(0xFF15803D),
                author: 'Aarav',
                repliesCount: 8,
                likesCount: 21,
              ),
              const SizedBox(height: 12),
            ],

            // Doubt Card 2
            _buildDoubtCard(
              title: 'Explain BCNF',
              badgeText: ' Waiting for Teacher',
              badgeIcon: Icons.access_time_filled,
              badgeBg: const Color(0xFFFEF3C7),
              badgeColor: const Color(0xFFB45309),
              author: 'Sita',
              repliesCount: 4,
            ),
            const SizedBox(height: 12),

            // Doubt Card 3
            if (_selectedDoubtFilter == 'All') ...[
              _buildDoubtCard(
                title: 'Difference between 2NF and 3NF',
                badgeText: ' Community Discussion',
                badgeIcon: Icons.groups,
                badgeBg: const Color(0xFFEFF6FF),
                badgeColor: const Color(0xFF1D4ED8),
                author: 'Ram',
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNavigationBar() : null,
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
        borderRadius: BorderRadius.circular(14),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label) {
    final isSelected = _selectedDoubtFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedDoubtFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildDoubtCard({
    required String title,
    required String badgeText,
    required IconData badgeIcon,
    required Color badgeBg,
    required Color badgeColor,
    required String author,
    int? repliesCount,
    int? likesCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 3),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
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
              fontWeight: FontWeight.w500,
            ),
          ),
          if (repliesCount != null || likesCount != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (repliesCount != null) ...[
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    '$repliesCount Replies',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (likesCount != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.thumb_up_outlined,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    '$likesCount Likes',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final navItems = [
      {'icon': Icons.home_outlined, 'label': 'Home'},
      {'icon': Icons.book, 'label': 'Subjects'},
      {'icon': Icons.notifications_none_outlined, 'label': 'Notifications'},
      {'icon': Icons.help_outline_rounded, 'label': 'Doubts'},
      {'icon': Icons.person_outline_rounded, 'label': 'Me'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final isSelected = _selectedNavIndex == index;
          final item = navItems[index];

          if (isSelected) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return InkWell(
            onTap: () => setState(() => _selectedNavIndex = index),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item['icon'] as IconData, color: const Color(0xFF64748B), size: 22),
                  const SizedBox(height: 2),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
