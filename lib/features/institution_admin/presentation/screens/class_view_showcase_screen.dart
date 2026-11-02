import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/clickable.dart';

import 'package:bridge_mobile/features/institution_admin/data/models/class_detail_model.dart';
import 'package:bridge_mobile/features/institution_admin/presentation/controllers/role_academic_providers.dart';
import 'subject_members_screen.dart';

class ClassDetailsScreen extends ConsumerStatefulWidget {
  final int classId;
  final String className;

  const ClassDetailsScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  ConsumerState<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends ConsumerState<ClassDetailsScreen> {
  String _selectedDoubtFilter = 'All';
  bool _isActionLoading = false;

  Future<void> _toggleClassStatus(ClassDetailModel details) async {
    setState(() => _isActionLoading = true);
    try {
      if (details.status.toUpperCase() == 'ACTIVE') {
        await suspendSubject(ref, widget.classId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Class suspended successfully.'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      } else {
        await activateSubject(ref, widget.classId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Class activated successfully.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
      // Refresh the details so the UI reflects the new status
      ref.invalidate(subjectDetailsProvider(widget.classId));
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
    final displayClassName =
        widget.className.isNotEmpty ? widget.className : 'Untitled Class';

    final detailsAsync = ref.watch(subjectDetailsProvider(widget.classId));

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
            detailsAsync.when(
              data: (d) {
                final parts = <String>[];
                if (d?.programName.isNotEmpty == true) parts.add(d!.programName);
                if (d?.classTeacherName?.isNotEmpty == true) parts.add(d!.classTeacherName!);
                return Text(
                  parts.isNotEmpty ? parts.join(' • ') : displayClassName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
              loading: () => const Text(
                'Loading...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          detailsAsync.when(
            data: (details) => PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
              onSelected: (val) {
                if (val == 'toggle_status' && details != null) {
                  _toggleClassStatus(details);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Text(
                    details?.status.toUpperCase() == 'ACTIVE'
                        ? 'Suspend Class'
                        : 'Activate Class',
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildErrorState(e.toString()),
        data: (details) => _buildBody(context, details, displayClassName),
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
  ) {
    final studentsCount = details?.totalStudents ?? 0;
    final hasAssignedTeacher = details?.classTeacherId != null;
    final teacherName = details?.classTeacherName ?? 'Not Assigned';
    final isActive = details?.status.toUpperCase() == 'ACTIVE';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Class Status Banner ────────────────────────────────────────────
          if (details != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF34D399)
                      : const Color(0xFFFCA5A5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                    color: isActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isActive
                          ? 'Class is Active — Students can access this subject.'
                          : 'Class is Suspended — Students cannot access this subject.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                  if (_isActionLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Clickable(
                      onTap: () => _toggleClassStatus(details),
                      child: Text(
                        isActive ? 'Suspend' : 'Activate',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        ),
                      ),
                    ),
                ],
              ),
            ),

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
                icon: Icons.person_add_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Manage Teacher',
                onTap: () {},
              ),
              _buildQuickActionCard(
                icon: Icons.group_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Manage Students',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectMembersScreen(
                        subjectId: widget.classId,
                        subjectName: displayClassName,
                        teacherName: teacherName,
                        totalStudents: studentsCount,
                        viewMode: ClassMembersViewMode.admin,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 3. Teacher Info Card ──────────────────────────────────────────
          const Text(
            'Instructor',
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
                        teacherName,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
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
          Container(
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
          ),
          const SizedBox(height: 24),
        ],
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
    return Clickable(
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