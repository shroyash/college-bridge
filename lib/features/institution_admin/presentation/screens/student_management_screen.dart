import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/datasources/student_admin_remote_datasource.dart';
import '../../data/datasources/academic_admin_remote_datasource.dart';
import '../../data/models/academic_level_model.dart';
import '../controllers/student_management_providers.dart';
import '../controllers/academic_management_providers.dart';

class StudentManagementScreen extends ConsumerStatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  ConsumerState<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState
    extends ConsumerState<StudentManagementScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(studentManagementProvider.notifier).init(),
    );
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        ref.read(studentManagementProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentManagementProvider);
    final notifier = ref.read(studentManagementProvider.notifier);

    ref.listen<StudentManagementState>(studentManagementProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ));
        notifier.clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.successMessage!),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ));
        notifier.clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(state, notifier),
      body: Column(
        children: [
          _buildFilterBar(state, notifier),
          if (state.hasSelection) _buildBulkActionBar(state, notifier),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF2563EB),
              onRefresh: notifier.refresh,
              child: state.isLoading && state.students.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF2563EB)))
                  : state.students.isEmpty && !state.isLoading
                      ? _buildEmptyState(state, notifier)
                      : _buildStudentList(state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(
      StudentManagementState state, StudentManagementNotifier notifier) {
    return AppBar(
      backgroundColor: const Color(0xFF1E40AF),
      elevation: 0,
      leading: state.hasSelection
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: notifier.clearSelection,
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
      title: state.hasSelection
          ? Text(
              '${state.selectedStudentIds.length} selected',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student Management',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17)),
                Text('${state.totalElements} total students',
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
      actions: [
        if (state.hasSelection)
          TextButton.icon(
            onPressed: notifier.toggleAll,
            icon: const Icon(Icons.select_all, color: Colors.white, size: 18),
            label: Text(
              state.selectedStudentIds.length == state.students.length
                  ? 'Deselect All'
                  : 'Select All',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        if (!state.hasSelection)
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: notifier.refresh,
          ),
      ],
    );
  }

  Widget _buildFilterBar(
      StudentManagementState state, StudentManagementNotifier notifier) {
    final faculties = state.filterOptions?.faculties ?? [];
    final semesters = state.filterOptions?.semesters ?? [];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (v) => notifier.setSearch(v),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        notifier.setSearch(null);
                      })
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Faculty + Semester row
          Row(
            children: [
              Expanded(
                child: _FilterDropdown<String>(
                  label: 'Faculty',
                  value: state.selectedFaculty,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Faculties')),
                    ...faculties.map(
                      (f) => DropdownMenuItem(value: f, child: Text(f)),
                    ),
                  ],
                  onChanged: notifier.setFacultyFilter,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterDropdown<int>(
                  label: 'Semester',
                  value: state.selectedSemester,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Semesters')),
                    ...semesters.map(
                      (s) =>
                          DropdownMenuItem(value: s, child: Text('Semester $s')),
                    ),
                  ],
                  onChanged: notifier.setSemesterFilter,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar(
      StudentManagementState state, StudentManagementNotifier notifier) {
    return Container(
      color: const Color(0xFF1E40AF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${state.selectedStudentIds.length} student(s) selected',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
          ElevatedButton.icon(
            onPressed: state.isTransferring
                ? null
                : () => _showTransferDialog(state, notifier),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: state.isTransferring
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF1E40AF)))
                : const Icon(Icons.swap_horiz,
                    color: Color(0xFF1E40AF), size: 18),
            label: Text(
              state.isTransferring ? 'Moving...' : 'Promote / Transfer',
              style: GoogleFonts.inter(
                  color: const Color(0xFF1E40AF),
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(
      StudentManagementState state, StudentManagementNotifier notifier) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: state.students.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == state.students.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB))),
          );
        }
        final s = state.students[i];
        final id = s.effectiveStudentId;
        final selected = state.selectedStudentIds.contains(id);
        return _StudentCard(
          student: s,
          selected: selected,
          onTap: () => notifier.toggleStudent(id),
          onLongPress: () => notifier.toggleStudent(id),
        );
      },
    );
  }

  Widget _buildEmptyState(
      StudentManagementState state, StudentManagementNotifier notifier) {
    final hasActiveFilters = state.selectedFaculty != null ||
        state.selectedSemester != null ||
        (state.searchQuery != null && state.searchQuery!.isNotEmpty);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined,
              size: 72, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters
                ? 'No students found matching filters'
                : 'No students found',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters
                ? 'Try adjusting or clearing your Search, Faculty, or Semester filter.'
                : 'There are currently no students registered.',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF94A3B8)),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                notifier.setSearch(null);
                notifier.setFacultyFilter(null);
                notifier.setSemesterFilter(null);
              },
              icon: const Icon(Icons.filter_alt_off, size: 16),
              label: const Text('Reset All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTransferDialog(
      StudentManagementState state, StudentManagementNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => _BulkTransferDialog(
        selectedCount: state.selectedStudentIds.length,
        currentFaculty: state.selectedFaculty,
        currentSemester: state.selectedSemester,
        dataSource: ref.read(academicAdminRemoteDataSourceProvider),
        onConfirm: (targetLevelId, targetDisplayName) async {
          final result = await notifier.bulkTransfer(targetLevelId);
          if (result != null && ctx.mounted) {
            Navigator.pop(ctx);
          }
        },
      ),
    );
  }
}

// ── Student Card ──────────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  final StudentSummary student;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _StudentCard({
    required this.student,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // Checkbox area
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFF2563EB) : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  student.name.isNotEmpty
                      ? student.name[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Class badge
            if (student.faculty != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      student.faculty!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    if (student.semester != null)
                      Text(
                        'Sem ${student.semester}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF4ADE80),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Dropdown ──────────────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF94A3B8))),
          isExpanded: true,
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Bulk Transfer Dialog ──────────────────────────────────────────────────

class _BulkTransferDialog extends ConsumerStatefulWidget {
  final int selectedCount;
  final String? currentFaculty;
  final int? currentSemester;
  final AcademicAdminRemoteDataSource dataSource;
  final Future<void> Function(int targetLevelId, String targetDisplayName)
      onConfirm;

  const _BulkTransferDialog({
    required this.selectedCount,
    required this.currentFaculty,
    required this.currentSemester,
    required this.dataSource,
    required this.onConfirm,
  });

  @override
  ConsumerState<_BulkTransferDialog> createState() =>
      _BulkTransferDialogState();
}

class _BulkTransferDialogState extends ConsumerState<_BulkTransferDialog> {
  List<AcademicLevelModel> _levels = [];
  bool _loadingClasses = true;
  AcademicLevelModel? _targetLevel;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    try {
      final programs = await widget.dataSource.getPrograms();
      final List<AcademicLevelModel> allLevels = [];
      for (final p in programs) {
        final lvls = await widget.dataSource.getLevels(programId: p.programId);
        allLevels.addAll(lvls);
      }
      if (mounted) setState(() { _levels = allLevels; _loadingClasses = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingClasses = false);
    }
  }

  bool get _isSameLevel {
    if (_targetLevel == null) return false;
    if (widget.currentSemester != null && _targetLevel!.levelNumber == widget.currentSemester) {
      if (widget.currentFaculty != null && widget.currentFaculty!.isNotEmpty) {
        return _targetLevel!.programName.trim().toLowerCase() == widget.currentFaculty!.trim().toLowerCase();
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentLabel = (widget.currentFaculty != null || widget.currentSemester != null)
        ? '${widget.currentFaculty ?? "?"} Semester ${widget.currentSemester ?? "?"}'
        : 'Mixed Cohorts';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Promote / Transfer Cohort',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${widget.selectedCount} student(s) selected • From: $currentLabel',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: _loadingClasses
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()))
          : _levels.isEmpty
              ? Text(
                  'No academic levels found. Please create academic levels first.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFFDC2626)))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Target Level:',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AcademicLevelModel>(
                          value: _targetLevel,
                          isExpanded: true,
                          hint: Text('Choose target level...',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 13)),
                          items: _levels
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      '${c.programName} - ${c.name}',
                                      style: GoogleFonts.inter(fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _targetLevel = v),
                        ),
                      ),
                    ),
                    if (_isSameLevel) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          '🚫 Target level cannot be the same as the current level/semester.',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFFDC2626),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ] else if (_targetLevel != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          '⚠️ ${widget.selectedCount} student(s) will be moved from $currentLabel to ${_targetLevel!.programName} ${_targetLevel!.name}. '
                          'Their existing subject enrollments will be replaced with subjects of the target level.',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ],
                ),
      actions: [
        TextButton(
          onPressed: _confirming ? null : () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF64748B))),
        ),
        ElevatedButton(
          onPressed: (_targetLevel == null || _isSameLevel || _confirming)
              ? null
              : () async {
                  setState(() => _confirming = true);
                  try {
                    await widget.onConfirm(
                        _targetLevel!.levelId, '${_targetLevel!.programName} ${_targetLevel!.name}');
                  } finally {
                    if (mounted) setState(() => _confirming = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: _confirming
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text('Confirm Transfer',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
