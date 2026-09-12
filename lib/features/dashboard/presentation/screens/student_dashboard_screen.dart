import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bridge_mobile/features/auth/presentation/controllers/institution_provider.dart';
import '../controllers/dashboard_providers.dart';
import '../controllers/dashboard_state.dart';
import '../../domain/entities/subject.dart';
import '../widgets/subject_card.dart';
import 'student_profile_screen.dart';
import 'package:bridge_mobile/features/institution_admin/presentation/controllers/role_academic_providers.dart';
import 'package:bridge_mobile/features/institution_admin/presentation/screens/student_classes_screen.dart';
import 'package:bridge_mobile/features/institution_admin/presentation/screens/student_subject_detail_screen.dart';
import 'package:bridge_mobile/features/institution_admin/presentation/screens/subject_members_screen.dart';
import 'package:bridge_mobile/features/doubt/presentation/screens/student_doubts_screen.dart';
import 'package:bridge_mobile/features/doubt/presentation/widgets/ask_doubt_dialog.dart';
import 'package:bridge_mobile/features/doubt/presentation/controllers/doubt_providers.dart';
import 'package:bridge_mobile/features/doubt/presentation/screens/doubt_detail_screen.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  final String userName;
  final VoidCallback? onLogout;
  const StudentDashboardScreen({super.key, required this.userName, this.onLogout});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  int _selectedBottomNavIndex = 0;

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
      ref.read(studentDashboardNotifierProvider.notifier).fetchMySubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentDashboardNotifierProvider);
    final classDetailAsync = ref.watch(studentClassDetailsProvider);
    final currentInstitution = ref.watch(currentInstitutionProvider);
    final recentDoubtsAsync = ref.watch(doubtsListProvider((subjectId: null, search: null)));

    final dynamicInstitutionName = currentInstitution != null && currentInstitution.name.isNotEmpty
        ? currentInstitution.name.toUpperCase()
        : classDetailAsync.when(
            data: (details) => (details != null && details.institutionName.isNotEmpty)
                ? details.institutionName.toUpperCase()
                : 'MY INSTITUTION',
            loading: () => 'FETCHING INSTITUTION...',
            error: (_, __) => 'MY INSTITUTION',
          );

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
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('👋', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Text(
                                '${_getGreeting()}, ${widget.userName.split(' ').first}',
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
                                '$dynamicInstitutionName • STUDENT • ${DateTime.now().year}',
                                style: const TextStyle(
                                  color: Color(0xFFBFDBFE),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Today',
                                style: TextStyle(
                                    color: Colors.blue[100], fontSize: 12),
                              ),
                            ],
                          )
                        ],
                      ),
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_none,
                                color: Colors.white),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('3',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.read(studentDashboardNotifierProvider.notifier).fetchMySubjects();
                      ref.invalidate(doubtsListProvider);
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QUICK ACTIONS',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                  child: _buildActionBtn(
                                      Icons.help_outline,
                                      'Ask Doubt',
                                      const Color(0xFF2563EB),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => const AskDoubtDialog(),
                                        ).then((posted) {
                                          if (posted == true) {
                                            ref.invalidate(doubtsListProvider);
                                          }
                                        });
                                      })),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: _buildActionBtn(
                                      Icons.chat_bubble_outline,
                                      'View Doubts',
                                      const Color(0xFF2563EB),
                                      onTap: () {
                                        setState(() => _selectedBottomNavIndex = 3);
                                      })),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                  child: _buildActionBtn(
                                      Icons.campaign_outlined,
                                      'Notices',
                                      const Color(0xFF9333EA))),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: _buildActionBtn(
                                      Icons.people_outline,
                                      'Members',
                                      const Color(0xFF2563EB),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const SubjectMembersScreen(
                                              subjectId: 0,
                                              subjectName: 'My Enrolled Class',
                                              teacherName: 'Teacher not assigned yet',
                                              isFromDashboard: true,
                                            ),
                                          ),
                                        );
                                      })),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'MY CLASSES',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() => _selectedBottomNavIndex = 1);
                                },
                                child: const Text('See all >',
                                    style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600)),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (state is DashboardLoading)
                            const Center(
                                child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ))
                          else if (state is DashboardFailure<List<Subject>>)
                            Center(
                                child: Text(state.message,
                                    style:
                                        const TextStyle(color: Colors.red)))
                          else if (state is DashboardSuccess<List<Subject>>)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: state.data.length,
                              itemBuilder: (context, index) {
                                final subject = state.data[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentSubjectDetailScreen(
                                          subjectId: subject.subjectId,
                                          subjectName: subject.name,
                                          teacherName: (subject.teacherName != null && subject.teacherName!.isNotEmpty)
                                              ? subject.teacherName!
                                              : 'Teacher not assigned',
                                        ),
                                      ),
                                    );
                                  },
                                  child: SubjectCard(
                                    title: subject.name,
                                    teacher: (subject.teacherName != null && subject.teacherName!.isNotEmpty)
                                        ? subject.teacherName!
                                        : 'Teacher not assigned',
                                    icon: _getSubjectIcon(subject.name),
                                    hasUpdates: index % 2 == 0,
                                    badgeText: index % 2 == 0
                                        ? '${index + 1} New'
                                        : 'No Updates',
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'YOUR DOUBTS',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() => _selectedBottomNavIndex = 3);
                                },
                                child: const Text('See all >',
                                    style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600)),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          recentDoubtsAsync.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (err, _) => Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                'Could not load recent doubts',
                                style: TextStyle(color: Colors.grey[600]),
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
                                  child: Column(
                                    children: [
                                      const Text(
                                        'No doubts asked yet',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Ask a question to start peer learning!',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final latestDoubt = doubts.first;
                              final isSolved = latestDoubt.status == 'RESOLVED' || latestDoubt.status == 'ANSWERED';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DoubtDetailScreen(doubtId: latestDoubt.doubtId),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(latestDoubt.subjectName,
                                              style: const TextStyle(
                                                  color: Color(0xFF2563EB),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isSolved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              latestDoubt.status,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isSolved ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(latestDoubt.question,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15)),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            isSolved ? Icons.check_circle : Icons.hourglass_empty,
                                            color: isSolved ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${latestDoubt.answerCount} answers • ${latestDoubt.verifiedAnswerCount} verified',
                                            style: TextStyle(
                                                color: isSolved ? Colors.green[700] : Colors.orange[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 1 – Subjects / Classes (Image 1 UI)
            StudentClassesScreen(
              onBack: () => setState(() => _selectedBottomNavIndex = 0),
            ),
            // 2 – Alerts (placeholder)
            const Center(child: Text('Notices')),
            // 3 – Doubts
            const StudentDoubtsScreen(),
            // 4 – Profile
            StudentProfileScreen(onLogout: widget.onLogout),

          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomNavIndex,
        onTap: (index) => setState(() => _selectedBottomNavIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF64748B),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined), label: 'Classes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined), label: 'Notices'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Doubts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('dbms') || lower.contains('data')) return Icons.storage;
    if (lower.contains('java') || lower.contains('program')) {
      return Icons.local_cafe;
    }
    if (lower.contains('os') || lower.contains('system')) return Icons.terminal;
    if (lower.contains('cn') || lower.contains('network')) {
      return Icons.account_tree;
    }
    return Icons.menu_book;
  }
}

