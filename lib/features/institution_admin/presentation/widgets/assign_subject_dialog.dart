import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admin_users/presentation/controllers/manage_users_providers.dart';
import '../../../admin_users/data/models/user_profile_model.dart';
import '../../../dashboard/data/models/subject_model.dart';

class AssignSubjectDialog extends ConsumerStatefulWidget {
  const AssignSubjectDialog({super.key});

  @override
  ConsumerState<AssignSubjectDialog> createState() => _AssignSubjectDialogState();
}

class _AssignSubjectDialogState extends ConsumerState<AssignSubjectDialog> {
  UserProfileModel? _selectedTeacher;
  List<UserProfileModel> _teachers = [];
  List<SubjectModel> _allSubjects = [];
  final Set<int> _selectedSubjectIds = {};
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final dataSource = ref.read(adminUserRemoteDataSourceProvider);
      final teachersList = await dataSource.filterUsers(role: 'TEACHER', status: 'ACTIVE');
      final subjectsList = await dataSource.getAllSubjects();

      if (mounted) {
        setState(() {
          _teachers = teachersList;
          _allSubjects = subjectsList;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _onTeacherSelected(UserProfileModel? teacher) async {
    if (teacher == null) return;
    setState(() {
      _selectedTeacher = teacher;
      _selectedSubjectIds.clear();
      _isLoadingData = true;
    });

    try {
      final dataSource = ref.read(adminUserRemoteDataSourceProvider);
      final assignments = await dataSource.getTeacherAssignments(teacher.userId);
      if (mounted) {
        setState(() {
          _selectedSubjectIds.addAll(assignments.map((a) => a.subjectId));
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _saveAssignments() async {
    if (_selectedTeacher == null) return;

    setState(() => _isSaving = true);
    try {
      final dataSource = ref.read(adminUserRemoteDataSourceProvider);
      await dataSource.replaceTeacherAssignments(
        _selectedTeacher!.userId,
        _selectedSubjectIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subjects assigned to ${_selectedTeacher!.name} successfully!'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.assignment_ind_outlined, color: Color(0xFF2563EB)),
          SizedBox(width: 8),
          Text('Assign Subject to Teacher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: _isLoadingData
          ? const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Teacher:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: DropdownButtonFormField<UserProfileModel>(
                      initialValue: _selectedTeacher,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      hint: const Text('Choose a teacher...'),
                      items: _teachers
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text('${t.name} (${t.email})'),
                              ))
                          .toList(),
                      onChanged: _onTeacherSelected,
                    ),
                  ),
                  if (_selectedTeacher != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Select Subjects for ${_selectedTeacher!.name}:',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _allSubjects.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No subjects found in institution.'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _allSubjects.length,
                              itemBuilder: (context, index) {
                                final subject = _allSubjects[index];
                                final isChecked = _selectedSubjectIds.contains(subject.subjectId);
                                return CheckboxListTile(
                                  title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: Text('${subject.programName} • ${subject.levelName} (${subject.creditHours} Credits)'),
                                  value: isChecked,
                                  activeColor: const Color(0xFF2563EB),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedSubjectIds.add(subject.subjectId);
                                      } else {
                                        _selectedSubjectIds.remove(subject.subjectId);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedTeacher == null || _isSaving ? null : _saveAssignments,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Assignments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
