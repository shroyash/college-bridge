import '../../../notifications/presentation/widgets/notification_badge_icon.dart';
import '../../../notifications/presentation/screens/broadcast_notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/clickable.dart';

import '../../../admin_users/domain/entities/teacher_assignment.dart';
import '../../../auth/presentation/controllers/institution_provider.dart';
import '../../../doubts/presentation/controllers/doubt_providers.dart';
import '../../../doubts/presentation/screens/doubt_detail_screen.dart';
import '../../../doubts/presentation/screens/student_doubts_screen.dart';
import '../../../institution_admin/presentation/screens/teacher_classes_screen.dart';
import '../../../institution_admin/presentation/screens/teacher_class_detail_screen.dart';
import '../../../subjects/presentation/screens/subject_members_screen.dart';
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
    this.teacherId = 0,
    this.onLogout,
  });

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  int _selectedBottomNavIndex = 0;
  final ScrollController _scrollController = ScrollController();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        bottom: false,
        child: IndexedStack(
          index: _selectedBottomNavIndex,
          children: [
            // 0 – Home
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(teacherDashboardNotifierProvider.notifier)
                          .fetchTeacherAssignments(widget.teacherId);
                      ref.invalidate(doubtsListProvider((subjectId: null, search: null)));
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickActions(),
                          const SizedBox(height: 28),
                          _buildMyClassesSection(state),
                          const SizedBox(height: 28),
                          Container(
                            child: _buildRequiresAttentionSection(),
                          ),
                          const SizedBox(height: 28),
                          _buildLatestNoticesSection(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 1 – Classes
            TeacherClassesScreen(
              onBack: () => setState(() => _selectedBottomNavIndex = 0),
            ),
            // 2 – Doubts
            StudentDoubtsScreen(
              onBack: () => setState(() => _selectedBottomNavIndex = 0),
            ),
            // 3 – Profile
            TeacherProfileScreen(
              totalClasses: totalClasses,
              onLogout: widget.onLogout,
              onBack: () => setState(() => _selectedBottomNavIndex = 0),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ── 1. Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final currentInstitution = ref.watch(currentInstitutionProvider);
    final dynamicInstitutionName = currentInstitution != null && currentInstitution.name.isNotEmpty
        ? currentInstitution.name.toUpperCase()
        : 'MY INSTITUTION';

    final firstName = widget.userName.isNotEmpty
        ? widget.userName.split(' ').first
        : 'Teacher';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('👋', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      '${_getGreeting()}, $firstName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.account_balance, color: Color(0xFFBFDBFE), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$dynamicInstitutionName • TEACHER • ${DateTime.now().year}',
                      style: const TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const NotificationBadgeIcon(),
        ],
      ),
    );
  }

  // ── 2. Quick Actions ────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final state = ref.read(teacherDashboardNotifierProvider);

    void navigateToMembers() {
      if (state is DashboardSuccess<List<TeacherAssignment>> &&
          state.data.isNotEmpty) {
        final first = state.data.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectMembersScreen(
              subjectId: first.subjectId,
              subjectName: first.subjectName,
              teacherName: '',
              totalStudents: 0,
              viewMode: ClassMembersViewMode.student,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No class assigned yet. Check back later.')),
        );
      }
    }

    final actions = <Map<String, Object?>>[
      {
        'title': 'Review Doubts',
        'icon': Icons.chat_bubble_outline_rounded,
        'action': () => setState(() => _selectedBottomNavIndex = 2),
      },
      {
        'title': 'My Classes',
        'icon': Icons.school_outlined,
        'action': () => setState(() => _selectedBottomNavIndex = 1),
      },
      {
        'title': 'Post Notice',
        'icon': Icons.campaign_outlined,
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BroadcastNotificationScreen()),
            ),
      },
      {
        'title': 'Members',
        'icon': Icons.people_outline_rounded,
        'action': navigateToMembers,
      },
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
            final VoidCallback onTapAction =
                action['action'] as VoidCallback;

            return InkWell(
              onTap: onTapAction,
              borderRadius: BorderRadius.circular(12),
              child: Container(
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
            Clickable(
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
                    'Loading classes...',
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
          _buildClassesGrid([]),
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
              'No class assigned',
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
        final semInt = item.semester ?? 1;

        return Clickable(
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
            hasUpdates: true,
            badgeText: 'ASSIGNED',
          ),
        );
      },
    );
  }

  // ── 4. Requires Your Attention Section (Dynamic Doubts Data) ───────────────
  Widget _buildRequiresAttentionSection() {
    final doubtsAsync = ref.watch(doubtsListProvider((subjectId: null, search: null)));

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
            Clickable(
              onTap: () => setState(() => _selectedBottomNavIndex = 2),
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
        doubtsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Could not load doubts: $err',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          data: (doubts) {
            if (doubts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 36, color: Color(0xFF16A34A)),
                    SizedBox(height: 8),
                    Text(
                      'No doubts require attention',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'All student questions in your classes have been addressed.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              );
            }

            final itemsToShow = doubts.take(3).toList();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemsToShow.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doubt = itemsToShow[index];
                final isSolved = doubt.status == 'RESOLVED' || doubt.status == 'ANSWERED';

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
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoubtDetailScreen(doubtId: doubt.doubtId),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFE2E8F0),
                              child: Text(
                                doubt.studentName.isNotEmpty
                                    ? doubt.studentName.substring(0, 1).toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doubt.question,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Student: ${doubt.studentName} • ${doubt.subjectName}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded,
                                    size: 14, color: Color(0xFF2563EB)),
                                const SizedBox(width: 6),
                                Text(
                                  '${doubt.answerCount} Answers',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DoubtDetailScreen(doubtId: doubt.doubtId),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
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
                                    'Solve / Verify',
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
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ── 5. Latest Notices Section ──────────────────────────────────────────────
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
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BroadcastNotificationScreen()),
                );
              },
              child: const Text('Post Notice'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BroadcastNotificationScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.campaign_outlined, size: 36, color: Color(0xFF2563EB)),
                SizedBox(height: 8),
                Text(
                  'Tap to post a campus notice',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
        ),
      ],
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
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Doubts',
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
