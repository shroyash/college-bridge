import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/clickable.dart';

import 'package:bridge_mobile/features/auth/presentation/controllers/institution_provider.dart';
import 'package:bridge_mobile/features/subjects/domain/entities/subject.dart';
import 'package:bridge_mobile/features/dashboard/presentation/controllers/dashboard_providers.dart';
import 'package:bridge_mobile/features/dashboard/presentation/controllers/dashboard_state.dart';
import 'package:bridge_mobile/features/dashboard/presentation/controllers/profile_notifier.dart';
import 'package:bridge_mobile/features/institution_admin/presentation/controllers/role_academic_providers.dart';
import 'package:bridge_mobile/features/academics/data/models/class_detail_model.dart';
import 'package:bridge_mobile/features/subjects/presentation/screens/student_subject_detail_screen.dart';

class StudentClassesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final bool showBottomNav;

  const StudentClassesScreen({
    super.key,
    this.onBack,
    this.showBottomNav = false,
  });

  @override
  ConsumerState<StudentClassesScreen> createState() =>
      _StudentClassesScreenState();
}

class _StudentClassesScreenState extends ConsumerState<StudentClassesScreen> {
  int _selectedNavIndex = 1; // 1 = Classes

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(studentDashboardNotifierProvider.notifier).fetchMySubjects();
      ref.read(profileNotifierProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentDashboardNotifierProvider);
    final classDetailAsync = ref.watch(studentClassDetailsProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final currentInstitution = ref.watch(currentInstitutionProvider);

    final profileStudentDetails = profileState is ProfileSuccess ? profileState.profile.studentDetails : null;

    final resolvedInstitutionName = (currentInstitution?.name != null && currentInstitution!.name.isNotEmpty)
        ? currentInstitution.name
        : classDetailAsync.when(
            data: (ClassDetailModel? details) =>
                (details != null && details.institutionName.isNotEmpty) ? details.institutionName : 'My Institution',
            loading: () => 'Fetching Institution...',
            error: (_, __) => 'My Institution',
          );

    final resolvedFaculty = (profileStudentDetails?.faculty != null && profileStudentDetails!.faculty!.isNotEmpty)
        ? profileStudentDetails.faculty!
        : classDetailAsync.when(
            data: (ClassDetailModel? details) =>
                (details != null && details.faculty.isNotEmpty) ? details.faculty : 'Enrolled Faculty',
            loading: () => 'Fetching Faculty...',
            error: (_, __) => 'Enrolled Faculty',
          );

    final semesterText = (profileStudentDetails?.semester != null && profileStudentDetails!.semester!.isNotEmpty)
        ? 'Semester ${profileStudentDetails.semester}'
        : classDetailAsync.when(
            data: (ClassDetailModel? details) => details != null ? 'Semester ${details.semester}' : 'Semester 3',
            loading: () => 'Semester 3',
            error: (_, __) => 'Semester 3',
          );

    final totalStudentsInClass = classDetailAsync.when(
      data: (ClassDetailModel? details) => details?.totalStudents ?? 24,
      loading: () => 24,
      error: (_, __) => 24,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2563EB), size: 24),
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        title: const Text(
          'My Classes',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF2563EB), size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(studentDashboardNotifierProvider.notifier).fetchMySubjects();
                ref.invalidate(studentClassDetailsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Institution & Faculty Header Banner
                    Container(
                      width: double.infinity,
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
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.account_balance, color: Color(0xFF2563EB), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'INSTITUTION',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      resolvedInstitutionName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.school_outlined, color: Color(0xFF7C3AED), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'FACULTY / PROGRAM',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      resolvedFaculty,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Academic Session Header
                    const Text(
                      'Academic Session',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          semesterText,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        if (state is DashboardSuccess<List<Subject>>)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${state.data.length} CLASSES',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '5 CLASSES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Classes List Content
                    if (state is DashboardLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (state is DashboardFailure<List<Subject>>)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
                              const SizedBox(height: 12),
                              Text(
                                (state as DashboardFailure).message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(studentDashboardNotifierProvider.notifier).fetchMySubjects();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (state is DashboardSuccess<List<Subject>>)
                      state.data.isEmpty
                          ? _buildFallbackSubjectList(totalStudentsInClass)
                          : _buildSubjectList(state.data, totalStudentsInClass)
                    else
                      _buildFallbackSubjectList(totalStudentsInClass),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _buildSubjectList(List<Subject> subjects, int totalStudents) {
    final mockUpdates = [3, 0, 2, 1, 0];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final teacherName = (subject.teacherName != null && subject.teacherName!.isNotEmpty)
            ? subject.teacherName!
            : 'Teacher not assigned';
        final newPostsCount = mockUpdates[index % mockUpdates.length];

        return _buildSubjectCard(
          subjectId: subject.subjectId,
          subjectName: subject.name,
          teacherName: teacherName,
          newPostsCount: newPostsCount,
          studentsCount: totalStudents,
        );
      },
    );
  }

  Widget _buildFallbackSubjectList(int totalStudents) {
    final fallbackData = [
      {'id': 101, 'name': 'Database Management System', 'teacher': 'Teacher not assigned', 'posts': 3},
      {'id': 102, 'name': 'Operating System', 'teacher': 'Teacher not assigned', 'posts': 0},
      {'id': 103, 'name': 'Java Programming', 'teacher': 'Teacher not assigned', 'posts': 2},
      {'id': 104, 'name': 'Computer Networks', 'teacher': 'Teacher not assigned', 'posts': 1},
      {'id': 105, 'name': 'Mathematics', 'teacher': 'Teacher not assigned', 'posts': 0},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fallbackData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = fallbackData[index];
        return _buildSubjectCard(
          subjectId: item['id'] as int,
          subjectName: item['name'] as String,
          teacherName: item['teacher'] as String,
          newPostsCount: item['posts'] as int,
          studentsCount: totalStudents,
        );
      },
    );
  }

  Widget _buildSubjectCard({
    required int subjectId,
    required String subjectName,
    required String teacherName,
    required int studentsCount,
    required int newPostsCount,
  }) {
    return Clickable(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentSubjectDetailScreen(
              subjectId: subjectId,
              subjectName: subjectName,
              teacherName: teacherName,
              studentsCount: studentsCount,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subjectName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          teacherName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (newPostsCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA855F7), Color(0xFF9333EA)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$newPostsCount NEW POST${newPostsCount > 1 ? 'S' : ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'No New Updates',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final navItems = [
      {'icon': Icons.home_outlined, 'label': 'Home'},
      {'icon': Icons.book, 'label': 'Classes'},
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
