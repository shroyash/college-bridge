import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin_users/domain/entities/teacher_assignment.dart';
import '../../../institution_admin/presentation/screens/teacher_classes_screen.dart';
import '../../../institution_admin/presentation/screens/teacher_class_detail_screen.dart';
import '../widgets/subject_card.dart';
import '../controllers/dashboard_providers.dart';
import '../controllers/dashboard_state.dart';
import 'teacher_profile_screen.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  final String userName;
  final int teacherId;
  final VoidCallback? onLogout;

  const TeacherDashboardScreen({
    super.key,
    required this.userName,
    this.teacherId =1,
    this.onLogout,
  });

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  int _selectedBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(teacherDashboardNotifierProvider.notifier)
          .fetchTeacherAssignments(widget.teacherId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherDashboardNotifierProvider);

    // Resolve total class count from state for the profile screen
    final totalClasses = state is DashboardSuccess<List<TeacherAssignment>>
        ? state.data.length
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedBottomNavIndex,
          children: [
            // 0 – Home
            RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(teacherDashboardNotifierProvider.notifier)
                    .fetchTeacherAssignments(widget.teacherId);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 28),
                    _buildMyClassesSection(state),
                    const SizedBox(height: 28),
                    _buildRequiresAttentionSection(),
                    const SizedBox(height: 28),
                    _buildLatestNoticesSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // 1 – Classes
            const TeacherClassesScreen(),
            // 2 – Notifications (placeholder)
            const Center(child: Text('Notifications')),
            // 3 – Profile
            TeacherProfileScreen(
                totalClasses: totalClasses, onLogout: widget.onLogout),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ── 1. Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final greetingName =
        widget.userName.isNotEmpty ? widget.userName : 'Teacher';

    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFCBD5E1),
          child: Icon(Icons.person, color: Color(0xFF475569), size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '👋 Good Morning, $greetingName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Assistant Professor • BCA',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                color: Color(0xFF0F172A),
                size: 22,
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: const Text(
                  '8',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 2. Quick Actions ────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {'title': 'Review Doubts', 'icon': Icons.chat_bubble_outline_rounded},
      {'title': 'Notices', 'icon': Icons.error_outline_rounded},
      {'title': 'Members', 'icon': Icons.people_outline_rounded},
      {'title': 'Broadcast', 'icon': Icons.sensors_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    action['icon'] as IconData,
                    color: const Color(0xFF2563EB),
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action['title'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── 3. My Classes Section (Dynamic API Call) ────────────────────────────────
  Widget _buildMyClassesSection(DashboardState<List<TeacherAssignment>> state) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Classes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBottomNavIndex = 1;
                });
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (state is DashboardLoading)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    'Loading classes from backend...',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          )
        else if (state is DashboardSuccess<List<TeacherAssignment>>)
          _buildClassesGrid(state.data)
        else if (state is DashboardFailure<List<TeacherAssignment>>)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (state as DashboardFailure).message,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(teacherDashboardNotifierProvider.notifier)
                        .fetchTeacherAssignments(widget.teacherId);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else
          _buildFallbackClassesGrid(),
      ],
    );
  }

  IconData _getSubjectIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('db') || lower.contains('data') || lower.contains('sql')) {
      return Icons.storage_rounded;
    } else if (lower.contains('os') || lower.contains('operating') || lower.contains('system')) {
      return Icons.laptop_chromebook_rounded;
    } else if (lower.contains('java') || lower.contains('code') || lower.contains('program')) {
      return Icons.code_rounded;
    } else if (lower.contains('network') || lower.contains('web')) {
      return Icons.hub_rounded;
    } else if (lower.contains('math') || lower.contains('stat')) {
      return Icons.functions_rounded;
    }
    return Icons.school_outlined;
  }

  Widget _buildClassesGrid(List<TeacherAssignment> assignments) {
    if (assignments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.school_outlined, size: 36, color: Color(0xFF94A3B8)),
            SizedBox(height: 8),
            Text(
              'No class assignments found from backend.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: assignments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final item = assignments[index];
        final facultyStr = item.faculty ?? 'BCA';
        final semInt = item.semester ?? 3;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherClassDetailScreen(
                  classId: item.subjectId,
                  className: '${item.subjectName} - $facultyStr Sem $semInt',
                ),
              ),
            );
          },
          child: SubjectCard(
            title: item.subjectName,
            teacher: '$facultyStr • Sem $semInt',
            icon: _getSubjectIcon(item.subjectName),
            hasUpdates: index % 2 == 0,
            badgeText: index % 2 == 0 ? 'ASSIGNED' : 'ACTIVE',
          ),
        );
      },
    );
  }

  Widget _buildFallbackClassesGrid() {
    final defaultClasses = [
      {'id': 101, 'name': 'Mathematics', 'faculty': 'BCA', 'sem': 1},
      {'id': 102, 'name': 'Database Management System', 'faculty': 'BCA', 'sem': 3},
      {'id': 103, 'name': 'Operating Systems', 'faculty': 'BCA', 'sem': 3},
      {'id': 104, 'name': 'Java Programming', 'faculty': 'BCA', 'sem': 5},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: defaultClasses.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final c = defaultClasses[index];
        final name = c['name'] as String;
        final faculty = c['faculty'] as String;
        final sem = c['sem'] as int;
        final id = c['id'] as int;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherClassDetailScreen(
                  classId: id,
                  className: '$name - $faculty Sem $sem',
                ),
              ),
            );
          },
          child: SubjectCard(
            title: name,
            teacher: '$faculty • Sem $sem',
            icon: _getSubjectIcon(name),
            hasUpdates: index % 2 == 0,
            badgeText: 'ASSIGNED',
          ),
        );
      },
    );
  }

  // ── 4. Requires Your Attention Section (Static) ────────────────────────────
  Widget _buildRequiresAttentionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Requires Your Attention',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Card 1: Doubt Question
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFC4B5FD),
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: '❓ ',
                                style: TextStyle(fontSize: 14),
                              ),
                              TextSpan(
                                text: 'What is Third Normal Form?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Student: Aarav • DBMS',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDE9FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF7C3AED),
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Text('⏳ ', style: TextStyle(fontSize: 11)),
                        Text(
                          'Waiting for your reply',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '15 minutes ago',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Card 2: Student Answer Needs Review
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE2E8F0),
                    child: Icon(Icons.person, color: Color(0xFF475569), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: '✔ ',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF16A34A)),
                              ),
                              TextSpan(
                                text: 'Student Answer Needs Review',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Topic: Difference between BCNF & 3NF',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Student: Sita • DBMS',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 14, color: Color(0xFF2563EB)),
                      SizedBox(width: 6),
                      Text(
                        '3 Community Answers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0265DC),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Review Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward,
                            size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 5. Latest Notices Section (Static) ──────────────────────────────────────
  Widget _buildLatestNoticesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Latest Notices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Notice Item 1
        _buildNoticeTile(
          icon: Icons.campaign_outlined,
          iconBg: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF0284C7),
          title: '📢 Mid-Term Exam Schedule',
          subtitle: 'Posted by You • Yesterday',
        ),
        const SizedBox(height: 10),

        // Notice Item 2
        _buildNoticeTile(
          icon: Icons.celebration_outlined,
          iconBg: const Color(0xFFF3E8FF),
          iconColor: const Color(0xFF9333EA),
          title: '🎉 Dashain Holiday Notice',
          subtitle: 'College Administration • 2 days ago',
        ),
      ],
    );
  }

  Widget _buildNoticeTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    );
  }

  // ── 6. Bottom Navigation Bar ───────────────────────────────────────────────
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedBottomNavIndex,
        onTap: (index) {
          setState(() {
            _selectedBottomNavIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedBottomNavIndex == 0
                    ? const Color(0xFF2563EB)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.home_filled,
                color: _selectedBottomNavIndex == 0
                    ? Colors.white
                    : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: 'Classes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
