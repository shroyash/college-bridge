import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/dashboard_providers.dart';
import '../controllers/dashboard_state.dart';
import '../../domain/entities/dashboard_metric.dart';
import '../widgets/metric_card.dart';
import '../widgets/quick_action_tile.dart';

import '../../../admin_users/presentation/screens/manage_users_screen.dart';
import '../../../admin_users/presentation/screens/register_teacher_screen.dart';
import '../../../institution_admin/presentation/screens/academic_management_screen.dart';
import '../../../institution_admin/presentation/screens/admin_profile_screen.dart';
import '../../../institution_admin/presentation/screens/institution_profile_screen.dart';
import '../../../institution_admin/presentation/screens/student_management_screen.dart';

import '../../../auth/presentation/controllers/institution_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  final String userName;
  final VoidCallback? onLogout;
  const AdminDashboardScreen({
    super.key,
    required this.userName,
    this.onLogout,
  });

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminDashboardNotifierProvider.notifier).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardNotifierProvider);
    final currentInstitution = ref.watch(currentInstitutionProvider);
    final displayInstitution = currentInstitution?.name;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E40AF), // Dark blue header
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.userName} • ${displayInstitution != null && displayInstitution.isNotEmpty ? displayInstitution : 'Administrator'}',
                          style: TextStyle(
                            color: Colors.blue[100],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const InstitutionProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: state is DashboardLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state is DashboardFailure
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            (state as DashboardFailure<List<DashboardMetric>>)
                                .message,
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(adminDashboardNotifierProvider.notifier)
                                  .fetchDashboard();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : state is DashboardSuccess<List<DashboardMetric>>
                  ? RefreshIndicator(
                      onRefresh: () => ref
                          .read(adminDashboardNotifierProvider.notifier)
                          .fetchDashboard(),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Metrics Grid
                            _buildMetricsGrid(state.data),
                            const SizedBox(height: 32),

                            // Quick Actions
                            const Text(
                              'QUICK ACTIONS',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            QuickActionTile(
                              title: 'Manage Academic Structure',
                              icon: Icons.school_outlined,
                              iconColor: const Color(0xFF9333EA),
                              iconBackgroundColor: const Color(0xFFF3E8FF),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AcademicManagementScreen(),
                                  ),
                                );
                              },
                            ),

                            QuickActionTile(
                              title: 'Teacher Registration',
                              icon: Icons.person_add_alt_1_outlined,
                              iconColor: const Color(0xFF10B981),
                              iconBackgroundColor: const Color(0xFFD1FAE5),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterTeacherScreen(),
                                  ),
                                );
                                if (context.mounted) {
                                  ref
                                      .read(
                                        adminDashboardNotifierProvider.notifier,
                                      )
                                      .fetchDashboard();
                                }
                              },
                            ),

                            QuickActionTile(
                              title: 'Assign Subjects to Teachers',
                              icon: Icons.assignment_ind_outlined,
                              iconColor: const Color(0xFF8B5CF6),
                              iconBackgroundColor: const Color(0xFFF5F3FF),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ManageUsersScreen(),
                                  ),
                                );
                                if (context.mounted) {
                                  ref
                                      .read(
                                        adminDashboardNotifierProvider.notifier,
                                      )
                                      .fetchDashboard();
                                }
                              },
                            ),

                            QuickActionTile(
                              title: 'Student Cohort & Transfer',
                              icon: Icons.swap_horiz_rounded,
                              iconColor: const Color(0xFF16A34A),
                              iconBackgroundColor: const Color(0xFFDCFCE7),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const StudentManagementScreen(),
                                  ),
                                );
                              },
                            ),

                            QuickActionTile(
                              title: 'Institution Profile',
                              icon: Icons.business_rounded,
                              iconColor: const Color(0xFF0284C7),
                              iconBackgroundColor: const Color(0xFFE0F2FE),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const InstitutionProfileScreen(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF64748B),
        showUnselectedLabels: true,
        onTap: (index) async {
          if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageUsersScreen(),
              ),
            );
            if (context.mounted) {
              ref
                  .read(adminDashboardNotifierProvider.notifier)
                  .fetchDashboard();
            }
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminProfileScreen(
                  userName: widget.userName,
                  onLogout: widget.onLogout,
                ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            label: 'Broadcast',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(List<dynamic> metrics) {
    // Helper to find metric by key
    int getValue(String key) {
      try {
        return metrics.firstWhere((m) => m.key == key).value;
      } catch (e) {
        return 0;
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.2, // wide cards
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        MetricCard(
          title: 'Students',
          value: getValue('students'),
          icon: Icons.people_alt,
          iconColor: const Color(0xFF3B82F6),
          iconBackgroundColor: const Color(0xFFEFF6FF),
          subtitle: 'Students',
        ),
        MetricCard(
          title: 'Classes',
          value: getValue('subjects'),
          icon: Icons.class_,
          iconColor: const Color(0xFF3B82F6),
          iconBackgroundColor: const Color(0xFFEFF6FF),
          subtitle: 'Classes',
        ),
        MetricCard(
          title: 'Teachers',
          value: getValue('teachers'),
          icon: Icons.co_present,
          iconColor: const Color(0xFF8B5CF6),
          iconBackgroundColor: const Color(0xFFF5F3FF),
          subtitle: 'Teachers',
        ),
        MetricCard(
          title: 'Total Programmes',
          value: getValue('programs'),
          icon: Icons.school,
          iconColor: const Color(0xFFEF4444),
          iconBackgroundColor: const Color(0xFFFEF2F2),
          subtitle: 'Programs',
        ),
      ],
    );
  }
}