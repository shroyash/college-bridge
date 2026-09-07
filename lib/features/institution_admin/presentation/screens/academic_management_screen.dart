import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/domain/entities/subject.dart';
import '../../domain/entities/academic_program.dart';
import '../controllers/academic_management_providers.dart';
import '../controllers/academic_management_state.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACADEMIC PROGRAMS',
                  style: TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...state.programs.map((prog) {
                        final isSelected = state.selectedProgram?.programId == prog.programId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${prog.name} (${prog.code})'),
                            selected: isSelected,
                            selectedColor: Colors.white,
                            backgroundColor: const Color(0xFF1D4ED8),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF1E40AF) : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                ref
                                    .read(academicManagementNotifierProvider.notifier)
                                    .selectProgram(prog);
                              }
                            },
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.add, size: 16, color: Colors.white),
                          label: const Text(
                            'Add Program',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: const Color(0xFF2563EB),
                          onPressed: () => _showAddProgramDialog(context),
                        ),
                      ),
                    ],
                  ),
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
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
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
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
            onPressed: () => _showEditSubjectDialog(context, subject),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            onPressed: () => _confirmDeleteSubject(context, subject),
          ),
        ],
      ),
    );
  }

  void _showAddProgramDialog(BuildContext context) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Academic Program', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Program Name', hintText: 'e.g. Bachelor of Computer Application'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Program Code', hintText: 'e.g. BCA'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final code = codeController.text.trim().toUpperCase();
              if (name.isNotEmpty && code.isNotEmpty) {
                final success = await ref
                    .read(academicManagementNotifierProvider.notifier)
                    .createProgram(name: name, code: code);
                if (success && context.mounted) Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Create Program', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddLevelDialog(BuildContext context, AcademicProgram program) {
    final numController = TextEditingController(text: '1');
    final nameController = TextEditingController(text: 'Semester 1');
    String levelType = 'SEMESTER';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add Level to ${program.code}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: levelType,
                decoration: const InputDecoration(labelText: 'Level Type'),
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
              TextField(
                controller: numController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Level Number', hintText: 'e.g. 1'),
                onChanged: (val) {
                  final num = int.tryParse(val) ?? 1;
                  nameController.text = levelType == 'SEMESTER' ? 'Semester $num' : 'Year $num';
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Level Name', hintText: 'e.g. First Semester'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final levelNum = int.tryParse(numController.text.trim()) ?? 1;
                final name = nameController.text.trim();
                final success = await ref
                    .read(academicManagementNotifierProvider.notifier)
                    .createLevel(
                      programId: program.programId,
                      levelNumber: levelNum,
                      name: name,
                      type: levelType,
                    );
                if (success && context.mounted) Navigator.pop(dialogCtx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Create Level', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final creditController = TextEditingController(text: '3');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Subject', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Subject Name')),
            const SizedBox(height: 12),
            TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Subject Code (Optional)')),
            const SizedBox(height: 12),
            TextField(controller: creditController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credit Hours')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              final credits = int.tryParse(creditController.text.trim()) ?? 3;
              if (name.isNotEmpty) {
                final success = await ref
                    .read(academicManagementNotifierProvider.notifier)
                    .createSubject(name: name, code: code.isNotEmpty ? code : null, creditHours: credits);
                if (success && context.mounted) Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Add Subject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, Subject subject) {
    final nameController = TextEditingController(text: subject.name);
    final codeController = TextEditingController(text: subject.code ?? '');
    final creditController = TextEditingController(text: subject.creditHours.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Subject', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Subject Name')),
            const SizedBox(height: 12),
            TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Subject Code')),
            const SizedBox(height: 12),
            TextField(controller: creditController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credit Hours')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              final credits = int.tryParse(creditController.text.trim()) ?? 3;
              if (name.isNotEmpty) {
                final success = await ref
                    .read(academicManagementNotifierProvider.notifier)
                    .updateSubject(
                      subjectId: subject.subjectId,
                      name: name,
                      code: code.isNotEmpty ? code : null,
                      creditHours: credits,
                    );
                if (success && context.mounted) Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBatchAddSubjectDialog(BuildContext context) {
    final batchController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batch Add Subjects', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter one subject per line (Format: Name | Code | CreditHours):',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: batchController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Mathematics I | MTH101 | 3\nDigital Logic | CSc102 | 3\nEnglish I | ENG103 | 2',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final text = batchController.text.trim();
              if (text.isNotEmpty) {
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
                  if (success && context.mounted) Navigator.pop(dialogCtx);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Batch Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubject(BuildContext context, Subject subject) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await ref
                  .read(academicManagementNotifierProvider.notifier)
                  .deleteSubject(subject.subjectId);
              if (success && context.mounted) Navigator.pop(dialogCtx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
