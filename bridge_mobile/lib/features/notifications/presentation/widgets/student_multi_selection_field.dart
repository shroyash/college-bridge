import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/clickable.dart';
import '../../../students/data/datasources/student_admin_remote_datasource.dart';
import '../../../students/presentation/controllers/student_management_providers.dart';

/// A searchable, paginated multi-selection widget for selecting students.
///
/// Features:
/// - Pagination of 10 students per page (size = 10).
/// - Search input with a dedicated "Search" button and keyboard submit.
/// - Multi-selection with checkboxes and tap-to-toggle rows.
/// - Selected students chip tray with single-tap removal and "Clear All".
/// - "Select All on Page" and "Deselect Page" batch controls.
/// - Full cursor/hover pointer support for web and desktop.
class StudentMultiSelectionField extends ConsumerStatefulWidget {
  final Map<int, StudentSummary> selectedStudents;
  final ValueChanged<Map<int, StudentSummary>> onSelectionChanged;

  const StudentMultiSelectionField({
    super.key,
    required this.selectedStudents,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<StudentMultiSelectionField> createState() =>
      _StudentMultiSelectionFieldState();
}

class _StudentMultiSelectionFieldState
    extends ConsumerState<StudentMultiSelectionField> {
  final _searchController = TextEditingController();

  static const int _pageSize = 10;
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = false;
  String? _errorMessage;
  List<StudentSummary> _students = [];
  String _activeSearchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchPage(0));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int page, {String? searchQuery}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final query = searchQuery ?? _activeSearchQuery;

    try {
      final dataSource = ref.read(studentAdminDataSourceProvider);
      final result = await dataSource.getStudents(
        page: page,
        size: _pageSize,
        search: query.isNotEmpty ? query : null,
      );

      if (mounted) {
        setState(() {
          _students = result.students;
          _currentPage = result.currentPage;
          _totalPages = result.totalPages;
          _totalElements = result.totalElements;
          _activeSearchQuery = query;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _performSearch() {
    final q = _searchController.text.trim();
    _fetchPage(0, searchQuery: q);
  }

  void _clearSearch() {
    _searchController.clear();
    _fetchPage(0, searchQuery: '');
  }

  void _toggleStudent(StudentSummary student) {
    final next = Map<int, StudentSummary>.from(widget.selectedStudents);
    if (next.containsKey(student.userId)) {
      next.remove(student.userId);
    } else {
      next[student.userId] = student;
    }
    widget.onSelectionChanged(next);
  }

  bool get _isAllCurrentPageSelected {
    if (_students.isEmpty) return false;
    return _students.every((s) => widget.selectedStudents.containsKey(s.userId));
  }

  void _toggleSelectCurrentPage() {
    final next = Map<int, StudentSummary>.from(widget.selectedStudents);
    if (_isAllCurrentPageSelected) {
      for (final s in _students) {
        next.remove(s.userId);
      }
    } else {
      for (final s in _students) {
        next[s.userId] = s;
      }
    }
    widget.onSelectionChanged(next);
  }

  void _clearAllSelected() {
    widget.onSelectionChanged({});
  }

  String _formatAcademicInfo(StudentSummary s) {
    final parts = <String>[];
    if (s.displayName != null && s.displayName!.isNotEmpty) {
      parts.add(s.displayName!);
    } else {
      if (s.faculty != null && s.faculty!.isNotEmpty) {
        parts.add(s.faculty!);
      }
      if (s.semester != null && s.semester! > 0) {
        parts.add('Sem ${s.semester}');
      }
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.selectedStudents.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header: Title & Selected Count ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text(
                  'Target Students',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selectedCount > 0
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedCount > 0
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Text(
                '$selectedCount selected',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selectedCount > 0
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Selected Students Tray (Chips) ───────────────────────────────────
        if (selectedCount > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected ($selectedCount):',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Clickable(
                      onTap: _clearAllSelected,
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.selectedStudents.values.map((student) {
                        return Chip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.white,
                          avatar: CircleAvatar(
                            backgroundColor: const Color(0xFF2563EB),
                            radius: 10,
                            child: Text(
                              student.name.isNotEmpty
                                  ? student.name[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          label: Text(
                            student.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          deleteIcon: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          onDeleted: () => _toggleStudent(student),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Search Bar with Search Button ────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                  decoration: InputDecoration(
                    hintText: 'Search by student name or email...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _performSearch,
                icon: const Icon(Icons.search, size: 18, color: Colors.white),
                label: const Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Batch Action & Status Row ────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _activeSearchQuery.isNotEmpty
                  ? 'Showing results for "$_activeSearchQuery"'
                  : 'Students List (10 per page)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            if (_students.isNotEmpty)
              Clickable(
                onTap: _toggleSelectCurrentPage,
                child: Text(
                  _isAllCurrentPageSelected
                      ? 'Deselect this page'
                      : 'Select this page',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // ── Students List Container ──────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: _buildListContent(),
        ),
        const SizedBox(height: 10),

        // ── Pagination Controls ──────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: (_currentPage > 0 && !_isLoading)
                  ? () => _fetchPage(_currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Previous', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  _totalPages > 0
                      ? 'Page ${_currentPage + 1} of $_totalPages'
                      : 'Page 1 of 1',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                Text(
                  '$_totalElements total students',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: (_currentPage < _totalPages - 1 && !_isLoading)
                  ? () => _fetchPage(_currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text('Next', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF2563EB),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Fetching students (10 per page)...',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36, color: Color(0xFFDC2626)),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _fetchPage(_currentPage),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }

    if (_students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 8),
              Text(
                _activeSearchQuery.isNotEmpty
                    ? 'No students found matching "$_activeSearchQuery"'
                    : 'No students found.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              if (_activeSearchQuery.isNotEmpty) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _clearSearch,
                  child: const Text('Clear search filter'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _students.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, index) {
        final student = _students[index];
        final isSelected = widget.selectedStudents.containsKey(student.userId);
        final academicInfo = _formatAcademicInfo(student);

        return Clickable(
          onTap: () => _toggleStudent(student),
          child: Container(
            color: isSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleStudent(student),
                  activeColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 17,
                  backgroundColor: isSelected
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFEFF6FF),
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : 'S',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ID #${student.userId}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        student.email,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (academicInfo.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          academicInfo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

