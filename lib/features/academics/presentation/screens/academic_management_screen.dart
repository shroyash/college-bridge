import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/domain/entities/subject.dart';
import '../../domain/entities/academic_level.dart';
import '../../domain/entities/academic_program.dart';
import '../controllers/academic_management_providers.dart';
import '../controllers/academic_management_state.dart';
import 'class_details_screen.dart';

class AcademicManagementScreen extends ConsumerStatefulWidget {
  const AcademicManagementScreen({super.key});

  @override
  ConsumerState<AcademicManagementScreen> createState() =>
      _AcademicManagementScreenState();
}

class _AcademicManagementScreenState
    extends ConsumerState<AcademicManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(academicManagementNotifierProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(academicManagementNotifierProvider);

    ref.listen<AcademicManagementState>(
      academicManagementNotifierProvider,
      (previous, next) {
        if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(academicManagementNotifierProvider.notifier).clearMessages();
        }
        if (next.successMessage != null && next.successMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(academicManagementNotifierProvider.notifier).clearMessages();
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Academic Structure & Curriculum',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(academicManagementNotifierProvider.notifier).init();
            },
          )
        ],
      ),
      body: Column(
        children: [
          // ── Program Selector Header ──
          Container(
            color: const Color(0xFF1E40AF),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACADEMIC PROGRAM',
                  style: TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showProgramPickerSheet(context, state),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3B82F6), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.school, color: Color(0xFF93C5FD), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: state.programs.isEmpty
                                    ? const Text(
                                        'No programs yet',
                                        style: TextStyle(color: Color(0xFF93C5FD), fontSize: 14),
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            state.selectedProgram?.name ?? 'Select a program',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (state.selectedProgram != null)
                                            Text(
                                              state.selectedProgram!.code,
                                              style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 11),
                                            ),
                                        ],
                                      ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E40AF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${state.programs.length} programs',
                                  style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (state.selectedProgram != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D4ED8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF3B82F6)),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            hoverColor: Colors.white10,
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                            tooltip: 'Program options',
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditProgramDialog(context, state.selectedProgram!);
                              } else if (value == 'delete') {
                                _confirmDeleteProgram(context, state.selectedProgram!);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit Program'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 18),
                                    SizedBox(width: 8),
                                    Text('Delete Program', style: TextStyle(color: Color(0xFFDC2626))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    // Quick add button
                    InkWell(
                      onTap: () => _showAddProgramDialog(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF3B82F6)),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),


          // ── Empty State if no programs ──
          if (state.programs.isEmpty && !state.isLoading) ...[
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school_outlined, size: 72, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 20),
                      const Text(
                        'No Programs Configured',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add your institution\'s academic programs (e.g. BCA, BBA, BSC_CSIT) to start managing curriculum levels and subjects.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddProgramDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add First Program', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // ── Level Selector Strip ──
            if (state.selectedProgram != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${state.selectedProgram!.name} LEVELS',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        InkWell(
                          onTap: () => _showAddLevelDialog(context, state.selectedProgram!),
                          child: const Row(
                            children: [
                              Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text(
                                'Add Level',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.loadingLevels)
                      const SizedBox(
                        height: 36,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else if (state.levels.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No levels created yet for this program.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: state.levels.map((lvl) {
                            final isSelected = state.selectedLevel?.levelId == lvl.levelId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilterChip(
                                    label: Text(lvl.name),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFF2563EB),
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF334155),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        ref
                                            .read(academicManagementNotifierProvider.notifier)
                                            .selectLevel(lvl);
                                      }
                                    },
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      size: 16,
                                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                    ),
                                    padding: EdgeInsets.zero,
                                    tooltip: 'Level options',
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditLevelDialog(context, lvl);
                                      } else if (value == 'delete') {
                                        _confirmDeleteLevel(context, lvl);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit Level'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 18),
                                            SizedBox(width: 8),
                                            Text('Delete Level', style: TextStyle(color: Color(0xFFDC2626))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),

            // ── Main Subject Directory Body ──
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.selectedLevel == null
                      ? const Center(child: Text('Select or create a level to view subjects.', style: TextStyle(color: Color(0xFF64748B))))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Overview Banner
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            state.selectedLevel!.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${state.selectedProgram!.name} • ${state.subjects.length} Subject(s)',
                                            style: const TextStyle(
                                              color: Color(0xFFDBEAFE),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.add, color: Colors.white, size: 28),
                                      tooltip: 'Add Options',
                                      onSelected: (value) {
                                        if (value == 'single') {
                                          _showAddSubjectDialog(context);
                                        } else if (value == 'batch') {
                                          _showBatchAddSubjectDialog(context);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'single',
                                          child: Row(
                                            children: [
                                              Icon(Icons.add_box, color: Color(0xFF2563EB)),
                                              SizedBox(width: 8),
                                              Text('Add Single Subject'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'batch',
                                          child: Row(
                                            children: [
                                              Icon(Icons.library_add, color: Color(0xFF16A34A)),
                                              SizedBox(width: 8),
                                              Text('Batch Add Subjects'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Section Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'CURRICULUM SUBJECTS',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    '${state.subjects.length} item(s)',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Subjects List
                              state.subjects.isEmpty
                                  ? _buildEmptySubjectState(context)
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: state.subjects.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final subject = state.subjects[index];
                                        return _buildSubjectCard(context, subject);
                                      },
                                    ),
                            ],
                          ),
                        ),
            ),
          ],
        ],
      ),
      floatingActionButton: state.selectedLevel != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSubjectDialog(context),
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Subject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildEmptySubjectState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.menu_book_outlined, size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          const Text(
            'No subjects added for this level',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add subjects individually or batch-import the curriculum.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAddSubjectDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Subject'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showBatchAddSubjectDialog(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                icon: const Icon(Icons.library_add, size: 18, color: Colors.white),
                label: const Text('Batch Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, Subject subject) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.book_outlined, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (subject.code != null && subject.code!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          subject.code!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${subject.creditHours} Credit Hrs',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassDetailsScreen(
                    classId: subject.subjectId,
                    className: subject.name,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('View Class', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
            tooltip: 'Subject Actions',
            onSelected: (value) {
              if (value == 'view') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassDetailsScreen(
                      classId: subject.subjectId,
                      className: subject.name,
                    ),
                  ),
                );
              } else if (value == 'edit') {
                _showEditSubjectDialog(context, subject);
              } else if (value == 'delete') {
                _confirmDeleteSubject(context, subject);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, color: Color(0xFF2563EB), size: 18),
                    SizedBox(width: 8),
                    Text('View Class Details'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 18),
                    SizedBox(width: 8),
                    Text('Edit Subject'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 8),
                    Text('Delete Subject', style: TextStyle(color: Color(0xFFDC2626))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProgramPickerSheet(BuildContext parentContext, AcademicManagementState state) {
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setSheetState) {
            final query = searchCtrl.text.toLowerCase();
            final filtered = state.programs
                .where((p) =>
                    p.name.toLowerCase().contains(query) ||
                    p.code.toLowerCase().contains(query))
                .toList();

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Transparent tap-area above the sheet → dismiss on tap
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => Navigator.pop(sheetCtx),
                    child: const SizedBox.expand(),
                  ),
                ),
                // Sheet itself — max 70% screen height
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(builderCtx).size.height * 0.70,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Academic Programs',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(sheetCtx);
                                  _showAddProgramDialog(parentContext);
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add'),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                        ),
                        // Search
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: TextField(
                            controller: searchCtrl,
                            autofocus: false,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search programs...',
                              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        // Programs List
                        Flexible(
                          child: filtered.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                    'No programs found',
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1, indent: 72),
                                  itemBuilder: (_, i) {
                                    final prog = filtered[i];
                                    final isSelected =
                                        state.selectedProgram?.programId == prog.programId;
                                    return ListTile(
                                      leading: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            prog.code.length > 3
                                                ? prog.code.substring(0, 3)
                                                : prog.code,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF2563EB),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        prog.name,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFF1E40AF)
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      subtitle: Text(
                                        prog.code,
                                        style: const TextStyle(
                                            color: Color(0xFF64748B), fontSize: 12),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected)
                                            const Padding(
                                              padding: EdgeInsets.only(right: 4),
                                              child: Icon(Icons.check_circle,
                                                  color: Color(0xFF2563EB), size: 20),
                                            ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert,
                                                color: Color(0xFF64748B), size: 20),
                                            tooltip: 'Program options',
                                            onSelected: (action) {
                                              Navigator.pop(sheetCtx);
                                              if (action == 'edit') {
                                                _showEditProgramDialog(parentContext, prog);
                                              } else if (action == 'delete') {
                                                _confirmDeleteProgram(parentContext, prog);
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_outlined,
                                                        color: Color(0xFF2563EB), size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Edit Program'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline,
                                                        color: Color(0xFFDC2626), size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Delete Program',
                                                        style: TextStyle(color: Color(0xFFDC2626))),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        ref
                                            .read(academicManagementNotifierProvider.notifier)
                                            .selectProgram(prog);
                                        Navigator.pop(sheetCtx);
                                      },
                                      onLongPress: () {
                                        Navigator.pop(sheetCtx);
                                        _showProgramActionsSheet(parentContext, prog);
                                      },
                                    );
                                  },
                                ),
                        ),
                        // Footer hint
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          child: Text(
                            'Tap to select  •  Click 3-dots or long-press for Edit / Delete',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );

      },
    );
  }

  void _showProgramActionsSheet(BuildContext parentContext, AcademicProgram prog) {
    showModalBottomSheet(
      context: parentContext,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${prog.name} (${prog.code})',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            const Text('Choose an action', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
              ),
              title: const Text('Edit Program', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Change name or code'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showEditProgramDialog(parentContext, prog);
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
              ),
              title: const Text('Delete Program',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
              subtitle: const Text('Removes all levels and subjects'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmDeleteProgram(parentContext, prog);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProgramDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final state = ref.watch(academicManagementNotifierProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Add Academic Program', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Program Name *',
                        hintText: 'e.g. Bachelor of Computer Application',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Program name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Program Code *',
                        hintText: 'e.g. BCA',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Program code is required.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: state.isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final name = nameController.text.trim();
                          final code = codeController.text.trim().toUpperCase();
                          final success = await ref
                              .read(academicManagementNotifierProvider.notifier)
                              .createProgram(name: name, code: code);
                          if (success && dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Program', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddLevelDialog(BuildContext context, AcademicProgram program) {
    final formKey = GlobalKey<FormState>();
    final numController = TextEditingController(text: '1');
    final nameController = TextEditingController(text: 'Semester 1');
    String levelType = 'SEMESTER';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final state = ref.watch(academicManagementNotifierProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Add Level to ${program.code}', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                        ),
                      ),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: levelType,
                      decoration: const InputDecoration(labelText: 'Level Type *'),
                      items: const [
                        DropdownMenuItem(value: 'SEMESTER', child: Text('Semester')),
                        DropdownMenuItem(value: 'YEAR', child: Text('Year')),
                        DropdownMenuItem(value: 'GRADE', child: Text('Grade')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => levelType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: numController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Level Number *', hintText: 'e.g. 1'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Level number is required.';
                        if (int.tryParse(val.trim()) == null) return 'Must be a valid integer.';
                        return null;
                      },
                      onChanged: (val) {
                        final num = int.tryParse(val) ?? 1;
                        nameController.text = levelType == 'SEMESTER' ? 'Semester $num' : 'Year $num';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Level Name *', hintText: 'e.g. First Semester'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Level name is required.';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: state.isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final levelNum = int.parse(numController.text.trim());
                          final name = nameController.text.trim();
                          final success = await ref
                              .read(academicManagementNotifierProvider.notifier)
                              .createLevel(
                                programId: program.programId,
                                levelNumber: levelNum,
                                name: name,
                                type: levelType,
                              );
                          if (success && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Level', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final creditController = TextEditingController(text: '3');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final state = ref.watch(academicManagementNotifierProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Add Subject', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Subject Name *'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Subject name is required.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Subject Code (Optional)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: creditController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Credit Hours *'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Credit hours is required.';
                        final parsed = int.tryParse(val.trim());
                        if (parsed == null || parsed < 1 || parsed > 10) {
                          return 'Credit hours must be between 1 and 10.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: state.isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final name = nameController.text.trim();
                          final code = codeController.text.trim();
                          final credits = int.parse(creditController.text.trim());
                          final success = await ref
                              .read(academicManagementNotifierProvider.notifier)
                              .createSubject(
                                name: name,
                                code: code.isNotEmpty ? code : null,
                                creditHours: credits,
                              );
                          if (success && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add Subject', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, Subject subject) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: subject.name);
    final codeController = TextEditingController(text: subject.code ?? '');
    final creditController = TextEditingController(text: subject.creditHours.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final state = ref.watch(academicManagementNotifierProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Subject', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Subject Name *'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Subject name is required.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Subject Code'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: creditController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Credit Hours *'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Credit hours is required.';
                        final parsed = int.tryParse(val.trim());
                        if (parsed == null || parsed < 1 || parsed > 10) {
                          return 'Credit hours must be between 1 and 10.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: state.isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final name = nameController.text.trim();
                          final code = codeController.text.trim();
                          final credits = int.parse(creditController.text.trim());
                          final success = await ref
                              .read(academicManagementNotifierProvider.notifier)
                              .updateSubject(
                                subjectId: subject.subjectId,
                                name: name,
                                code: code.isNotEmpty ? code : null,
                                creditHours: credits,
                                levelId: subject.levelId,
                              );
                          if (success && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBatchAddSubjectDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final batchController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final state = ref.watch(academicManagementNotifierProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Batch Add Subjects', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                        ),
                      ),
                    ],
                    const Text(
                      'Enter one subject per line (Format: Name | Code | CreditHours):',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: batchController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Mathematics I | MTH101 | 3\nDigital Logic | CSc102 | 3\nEnglish I | ENG103 | 2',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Batch entries cannot be empty.';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: state.isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final text = batchController.text.trim();
                          final lines = text.split('\n');
                          final List<Map<String, dynamic>> items = [];
                          for (final line in lines) {
                            final parts = line.split('|').map((e) => e.trim()).toList();
                            if (parts.isNotEmpty && parts[0].isNotEmpty) {
                              items.add({
                                'name': parts[0],
                                'code': parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
                                'creditHours': parts.length > 2 ? int.tryParse(parts[2]) ?? 3 : 3,
                              });
                            }
                          }
                          if (items.isNotEmpty) {
                            final success = await ref
                                .read(academicManagementNotifierProvider.notifier)
                                .batchCreateSubjects(subjects: items);
                            if (success && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Batch Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteSubject(BuildContext context, Subject subject) {
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final state = ref.watch(academicManagementNotifierProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Subject', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                    ),
                  ),
                ],
                Text('Are you sure you want to delete "${subject.name}"?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: state.isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        final success = await ref
                            .read(academicManagementNotifierProvider.notifier)
                            .deleteSubject(subject.subjectId);
                        if (success && dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Program Edit / Delete ──────────────────────────────────────────────────

  void _showEditProgramDialog(BuildContext context, AcademicProgram program) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: program.name);
    final codeController = TextEditingController(text: program.code);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final state = ref.watch(academicManagementNotifierProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Academic Program', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Program Name *', hintText: 'e.g. Bachelor of Computer Application'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Program name is required.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Program Code *', hintText: 'e.g. BCA'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Program code is required.';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: state.isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final name = nameController.text.trim();
                          final code = codeController.text.trim().toUpperCase();
                          final success = await ref
                              .read(academicManagementNotifierProvider.notifier)
                              .updateProgram(programId: program.programId, name: name, code: code);
                          if (success && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteProgram(BuildContext context, AcademicProgram program) {
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final state = ref.watch(academicManagementNotifierProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Program', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                    ),
                  ),
                ],
                Text('Are you sure you want to delete "${program.name} (${program.code})"?'),
                const SizedBox(height: 8),
                const Text(
                  'This will also delete all levels and subjects under this program.',
                  style: TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: state.isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        final success = await ref
                            .read(academicManagementNotifierProvider.notifier)
                            .deleteProgram(program.programId);
                        if (success && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Level Edit / Delete ───────────────────────────────────────────────────

  void _showEditLevelDialog(BuildContext context, AcademicLevel level) {
    final formKey = GlobalKey<FormState>();
    final numController = TextEditingController(text: level.levelNumber.toString());
    final nameController = TextEditingController(text: level.name);
    String levelType = level.type;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final state = ref.watch(academicManagementNotifierProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Level', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                        ),
                      ),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: levelType,
                      decoration: const InputDecoration(labelText: 'Level Type *'),
                      items: const [
                        DropdownMenuItem(value: 'SEMESTER', child: Text('Semester')),
                        DropdownMenuItem(value: 'YEAR', child: Text('Year')),
                        DropdownMenuItem(value: 'GRADE', child: Text('Grade')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => levelType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: numController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Level Number *', hintText: 'e.g. 1'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Level number is required.';
                        if (int.tryParse(val.trim()) == null) return 'Must be a valid integer.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Level Name *', hintText: 'e.g. First Semester'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Level name is required.';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: state.isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final levelNum = int.parse(numController.text.trim());
                          final name = nameController.text.trim();
                          final success = await ref
                              .read(academicManagementNotifierProvider.notifier)
                              .updateLevel(
                                levelId: level.levelId,
                                levelNumber: levelNum,
                                name: name,
                                type: levelType,
                              );
                          if (success && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteLevel(BuildContext context, AcademicLevel level) {
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final state = ref.watch(academicManagementNotifierProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Level', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                    ),
                  ),
                ],
                Text('Are you sure you want to delete "${level.name}"?'),
                const SizedBox(height: 8),
                const Text(
                  'This will also delete all subjects under this level.',
                  style: TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: state.isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        final success = await ref
                            .read(academicManagementNotifierProvider.notifier)
                            .deleteLevel(level.levelId);
                        if (success && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
