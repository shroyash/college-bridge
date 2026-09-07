import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/manage_users_notifier.dart';
import '../controllers/manage_users_providers.dart';
import '../controllers/manage_users_state.dart';
import '../../domain/entities/user_profile.dart';
import 'assign_classes_screen.dart';
import 'register_teacher_screen.dart';
import '../widgets/student_details_dialog.dart';
import '../../../institution_admin/presentation/screens/student_management_screen.dart';

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(manageUsersNotifierProvider.notifier).fetchUsers(
            role: 'TEACHER',
            status: 'ACTIVE',
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manageUsersNotifierProvider);
    final notifier = ref.read(manageUsersNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFF1F5F9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Manage Users',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      floatingActionButton: notifier.currentRole == 'TEACHER'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterTeacherScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF0265DC),
              icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
              label: const Text(
                'Add Teacher',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentManagementScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF1E40AF),
              icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
              label: const Text(
                'Cohort Filters & Transfer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => notifier.search(val),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle:
                    const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF64748B), size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

          // Role Segmented Tabs (Teachers | Students)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => notifier.selectRoleTab('TEACHER'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: notifier.currentRole == 'TEACHER'
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: notifier.currentRole == 'TEACHER'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          'Teachers',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: notifier.currentRole == 'TEACHER'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => notifier.selectRoleTab('STUDENT'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: notifier.currentRole == 'STUDENT'
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: notifier.currentRole == 'STUDENT'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          'Students',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: notifier.currentRole == 'STUDENT'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Status Filter Chips (Active | Suspended)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Active'),
                  selected: notifier.currentStatus == 'ACTIVE',
                  onSelected: (selected) {
                    if (selected) notifier.selectStatusTab('ACTIVE');
                  },
                  selectedColor: const Color(0xFFDBEAFE),
                  checkmarkColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                    color: notifier.currentStatus == 'ACTIVE'
                        ? const Color(0xFF1E40AF)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Suspended'),
                  selected: notifier.currentStatus == 'SUSPENDED',
                  onSelected: (selected) {
                    if (selected) notifier.selectStatusTab('SUSPENDED');
                  },
                  selectedColor: const Color(0xFFFEE2E2),
                  checkmarkColor: const Color(0xFFDC2626),
                  labelStyle: TextStyle(
                    color: notifier.currentStatus == 'SUSPENDED'
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (notifier.currentRole == 'STUDENT')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bulk Cohort Transfer',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Filter by Faculty & Sem • Promote or transfer students in batch',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentManagementScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E40AF),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Open',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),

          // User List View
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.fetchUsers(),
              child: state is ManageUsersLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state is ManageUsersFailure
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(state.message),
                              TextButton(
                                onPressed: () => notifier.fetchUsers(),
                                child: const Text('Retry'),
                              )
                            ],
                          ),
                        )
                      : state is ManageUsersSuccess
                          ? state.users.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No users found.',
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  itemCount: state.users.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final user = state.users[index];
                                    if (notifier.currentRole == 'TEACHER') {
                                      return _buildTeacherCard(context, user, notifier);
                                    } else {
                                      return _buildStudentCard(context, user, notifier);
                                    }
                                  },
                                )
                          : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(
      BuildContext context, UserProfile user, ManageUsersNotifier notifier) {
    final initials = user.name.isNotEmpty
        ? user.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'T';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: Color(0xFF2563EB), width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage:
                    user.imageUrl != null ? NetworkImage(user.imageUrl!) : null,
                child: user.imageUrl == null
                    ? Text(
                        initials.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Faculty Member • ${user.role}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: Color(0xFF334155)),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssignClassesScreen(
                          teacherId: user.teacherId!,
                          teacherName: user.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bookmark_outline,
                      size: 16, color: Colors.white),
                  label: const Text(
                    'Assign Subjects',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(user.isActive ? 'Suspend User' : 'Activate User'),
                    content: Text(
                        'Are you sure you want to ${user.isActive ? "suspend" : "activate"} ${user.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(user.isActive ? 'Suspend' : 'Activate'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final success = user.isActive
                      ? await notifier.suspendUser(user.userId)
                      : await notifier.activateUser(user.userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Teacher ${user.isActive ? "suspended" : "activated"} successfully.'
                              : 'Failed to update teacher status.',
                        ),
                        backgroundColor: success
                            ? (user.isActive ? Colors.red : Colors.green)
                            : Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: Icon(
                user.isActive
                    ? Icons.block
                    : Icons.check_circle_outline,
                size: 16,
                color: user.isActive
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF16A34A),
              ),
              label: Text(
                user.isActive ? 'Suspend' : 'Activate',
                style: TextStyle(
                  color: user.isActive
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF16A34A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(
                  color: user.isActive
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFF86EFAC),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStudentCard(
      BuildContext context, UserProfile user, ManageUsersNotifier notifier) {
    final initials = user.name.isNotEmpty
        ? user.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'ST';

    final facultyText = user.studentDetails?.faculty ?? 'BSc. Computer Science';
    final studentIdText =
        user.studentDetails?.academicClassId != null
            ? 'ID: 2024-${user.studentDetails!.academicClassId.toString().padLeft(3, "0")}'
            : 'ID: 2024-${user.userId.toString().padLeft(3, "0")}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: Color(0xFF2563EB), width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage:
                    user.imageUrl != null ? NetworkImage(user.imageUrl!) : null,
                child: user.imageUrl == null
                    ? Text(
                        initials.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      facultyText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          studentIdText,
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => StudentDetailsDialog(student: user),
                );
              },
              icon: const Icon(Icons.person_outline,
                  size: 16, color: Color(0xFF334155)),
              label: const Text(
                'View Profile',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(user.isActive ? 'Suspend Student' : 'Activate Student'),
                    content: Text(
                        'Are you sure you want to ${user.isActive ? "suspend" : "activate"} ${user.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(user.isActive ? 'Suspend' : 'Activate'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final success = user.isActive
                      ? await notifier.suspendUser(user.userId)
                      : await notifier.activateUser(user.userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Student ${user.isActive ? "suspended" : "activated"} successfully.'
                              : 'Failed to update student status.',
                        ),
                        backgroundColor: success
                            ? (user.isActive ? Colors.red : Colors.green)
                            : Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: Icon(
                user.isActive
                    ? Icons.block
                    : Icons.check_circle_outline,
                size: 16,
                color: user.isActive
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF16A34A),
              ),
              label: Text(
                user.isActive ? 'Suspend' : 'Activate',
                style: TextStyle(
                  color: user.isActive
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF16A34A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(
                  color: user.isActive
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFF86EFAC),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
