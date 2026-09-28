import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bridge_mobile/features/academics/data/models/class_detail_model.dart';
import 'package:bridge_mobile/features/institution_admin/presentation/controllers/role_academic_providers.dart';

enum ClassMembersViewMode { student, teacher, admin }

class SubjectMembersScreen extends ConsumerStatefulWidget {
  final int subjectId;
  final String subjectName;
  final String teacherName;
  final int totalStudents;
  final bool isFromDashboard;
  final ClassMembersViewMode viewMode;

  const SubjectMembersScreen({
    super.key,
    required this.subjectId,
    this.subjectName = '',
    this.teacherName = '',
    this.totalStudents = 0,
    this.isFromDashboard = false,
    this.viewMode = ClassMembersViewMode.student,
  });

  @override
  ConsumerState<SubjectMembersScreen> createState() => _SubjectMembersScreenState();
}

class _SubjectMembersScreenState extends ConsumerState<SubjectMembersScreen> {
  String _searchQuery = '';
  bool _isActionLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Colors derived deterministically from student name initials ─────────────
  static const List<Color> _avatarColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFF6366F1),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFF84CC16),
  ];

  Color _avatarColorFor(String name) {
    final hash = name.isEmpty ? 0 : name.codeUnits.fold(0, (a, b) => a + b);
    return _avatarColors[hash % _avatarColors.length];
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '??';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _toggleStudentStatus(
    ClassStudentModel student,
    bool isSuspended,
  ) async {
    setState(() => _isActionLoading = true);
    try {
      final ds = ref.read(academicAdminRemoteDataSourceProvider);

      if (isSuspended) {
        await ds.activateStudentInSubject(widget.subjectId, student.studentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${student.fullName} has been reactivated.'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        await ds.suspendStudentInSubject(widget.subjectId, student.studentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${student.fullName} has been suspended.'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }

      // Force immediate re-fetch so the card flips right away.
      if (mounted) {
        final refreshFuture = ref.refresh(subjectDetailsProvider(widget.subjectId).future);
        await refreshFuture;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(subjectDetailsProvider(widget.subjectId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2563EB), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Class Members',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_isActionLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildErrorState(e.toString()),
        data: (details) => _buildBody(details),
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
              onPressed: () => ref.invalidate(subjectDetailsProvider(widget.subjectId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ClassDetailModel? details) {
    final displaySubjectName = widget.subjectName.isNotEmpty
        ? widget.subjectName
        : (details?.displayName ?? 'Class');
    final hasAssignedTeacher = details?.classTeacherId != null;
    final displayTeacherName = (details?.classTeacherName?.isNotEmpty == true)
        ? details!.classTeacherName!
        : (widget.teacherName.isNotEmpty ? widget.teacherName : 'No teacher assigned');
    final totalCount = details?.totalStudents ?? widget.totalStudents;

    // Filter students by search query
    final allStudents = details?.students ?? [];
    final filteredStudents = _searchQuery.isEmpty
        ? allStudents
        : allStudents.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.fullName.toLowerCase().contains(q) ||
                s.email.toLowerCase().contains(q);
          }).toList();

    String searchHintText;
    switch (widget.viewMode) {
      case ClassMembersViewMode.student:
        searchHintText = 'Search classmates by name...';
        break;
      case ClassMembersViewMode.teacher:
        searchHintText = 'Search students by name or email...';
        break;
      case ClassMembersViewMode.admin:
        searchHintText = 'Search by name or email...';
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Directory Header Banner ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displaySubjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCount students enrolled',
                  style: const TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 2. Teacher Info (visible to all roles) ─────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasAssignedTeacher ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school_outlined,
                    color: hasAssignedTeacher ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTeacherName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'Primary Faculty',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasAssignedTeacher ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasAssignedTeacher ? 'ASSIGNED' : 'UNASSIGNED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: hasAssignedTeacher ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 3. Search Field ────────────────────────────────────────────────
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: searchHintText,
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 4. Students List Header ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Students (${filteredStudents.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (widget.viewMode == ClassMembersViewMode.student)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'View Only',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── 5. Students List ───────────────────────────────────────────────
          if (filteredStudents.isEmpty)
            _buildEmptyStudents()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredStudents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                final isSuspended = student.status.toUpperCase() == 'SUSPENDED';
                return _buildStudentCard(student, isSuspended);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyStudents() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.group_off_outlined, color: Color(0xFFCBD5E1), size: 40),
            SizedBox(height: 10),
            Text(
              'No students found',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(ClassStudentModel student, bool isSuspended) {
    final avatarColor = _avatarColorFor(student.fullName);
    final initials = _initialsFor(student.fullName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isSuspended ? const Color(0xFFFFF1F2) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSuspended ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
        ),
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
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSuspended ? const Color(0xFFEF4444) : avatarColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name & email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        student.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSuspended
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (isSuspended) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SUSPENDED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  student.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action button (Teacher & Admin only)
          if (widget.viewMode == ClassMembersViewMode.teacher ||
              widget.viewMode == ClassMembersViewMode.admin)
            _buildStudentActionButton(student, isSuspended),
        ],
      ),
    );
  }

  Widget _buildStudentActionButton(ClassStudentModel student, bool isSuspended) {
    if (isSuspended) {
      return TextButton(
        onPressed: _isActionLoading ? null : () => _toggleStudentStatus(student, true),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF059669),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF34D399)),
          ),
        ),
        child: const Text(
          'Reactivate',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return TextButton(
        onPressed: _isActionLoading ? null : () => _toggleStudentStatus(student, false),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFDC2626),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFFCA5A5)),
          ),
        ),
        child: const Text(
          'Suspend',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }
  }
}