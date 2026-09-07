import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/academic_management_providers.dart';
import '../../data/models/class_detail_model.dart';
import '../widgets/student_details_modal.dart';
import '../../../admin_users/presentation/controllers/manage_users_providers.dart';
import '../../../admin_users/data/models/user_profile_model.dart';

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

class _ClassDetailsScreenState extends ConsumerState<ClassDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ClassDetailModel? _classDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClassDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClassDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dataSource = ref.read(academicAdminRemoteDataSourceProvider);
      final details = await dataSource.getClassDetails(widget.classId);
      if (mounted) {
        setState(() {
          _classDetail = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeStudent(ClassStudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student from Class'),
        content: Text('Are you sure you want to remove ${student.fullName} from this class? They will become unassigned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dataSource = ref.read(academicAdminRemoteDataSourceProvider);
        await dataSource.removeStudentFromClass(widget.classId, student.studentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${student.fullName} removed from class.')),
          );
          _loadClassDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showAddStudentModal() async {
    try {
      final dataSource = ref.read(academicAdminRemoteDataSourceProvider);
      final unassigned = await dataSource.getUnassignedStudents();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _AddStudentSheet(
          unassignedStudents: unassigned,
          onAdd: (studentId) async {
            Navigator.pop(ctx);
            try {
              await dataSource.addStudentToClass(widget.classId, studentId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student added to class successfully!'), backgroundColor: Color(0xFF16A34A)),
                );
                _loadClassDetails();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.red),
                );
              }
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching unassigned students: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _assignClassTeacherModal() async {
    try {
      final adminUserDs = ref.read(adminUserRemoteDataSourceProvider);
      final teachers = await adminUserDs.filterUsers(role: 'TEACHER', status: 'ACTIVE');

      if (!mounted) return;

      UserProfileModel? selectedTeacher;
      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            title: const Text('Assign Class Teacher'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select primary class teacher:'),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserProfileModel>(
                  initialValue: selectedTeacher,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  hint: const Text('Choose teacher...'),
                  items: teachers.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                  onChanged: (val) => setModalState(() => selectedTeacher = val),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: selectedTeacher == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final academicDs = ref.read(academicAdminRemoteDataSourceProvider);
                          await academicDs.assignClassTeacher(widget.classId, selectedTeacher!.userId);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('${selectedTeacher!.name} designated as Class Teacher.')),
                            );
                            _loadClassDetails();
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                child: const Text('Assign', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teachers: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _classDetail?.displayName ?? widget.className,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadClassDetails,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blue[200],
          tabs: const [
            Tab(text: 'Students'),
            Tab(text: 'Teachers'),
            Tab(text: 'Class Admin'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadClassDetails, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: const Color(0xFF1E40AF),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.class_outlined, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_classDetail!.faculty} • Semester ${_classDetail!.semester}',
                                  style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _classDetail!.displayName,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, color: Colors.white70, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Class Teacher: ${_classDetail!.classTeacherName ?? "Not Designated"}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_classDetail!.totalStudents} Students',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab View Body
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStudentsTab(),
                          _buildTeachersTab(),
                          _buildAdminTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStudentsTab() {
    final students = _classDetail!.students;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ENROLLED STUDENTS (${students.length})',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddStudentModal,
                icon: const Icon(Icons.person_add, size: 16, color: Colors.white),
                label: const Text('Add Student', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              ),
            ],
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      const Text('No students currently assigned to this class.', style: TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showAddStudentModal,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                        child: const Text('Add First Student', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDBEAFE),
                          child: Text(
                            student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                            style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(student.email, style: const TextStyle(fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                              tooltip: 'View Student Details',
                              onPressed: () => StudentDetailsModal.show(context, student),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFDC2626)),
                              tooltip: 'Remove from Class',
                              onPressed: () => _removeStudent(student),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTeachersTab() {
    final teachers = _classDetail!.teachers;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ASSIGNED SUBJECT TEACHERS',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              OutlinedButton.icon(
                onPressed: _assignClassTeacherModal,
                icon: const Icon(Icons.star_outline, size: 16),
                label: const Text('Set Class Teacher'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          teachers.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'No subject teachers assigned to this class yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: teachers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: teacher.isClassTeacher ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                          width: teacher.isClassTeacher ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFF3E8FF),
                                  child: Text(
                                    teacher.fullName.isNotEmpty ? teacher.fullName[0].toUpperCase() : 'T',
                                    style: const TextStyle(color: Color(0xFF9333EA), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(teacher.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          if (teacher.isClassTeacher) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDBEAFE),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Text('CLASS TEACHER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(teacher.email, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (teacher.assignedSubjects.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text('Taught Subjects:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: teacher.assignedSubjects
                                    .map((sub) => Chip(
                                          label: Text(sub, style: const TextStyle(fontSize: 11)),
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildAdminTab() {
    final detail = _classDetail!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CLASS MANAGEMENT INFO', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildTile('Class ID', '${detail.classId}'),
                const Divider(),
                _buildTile('Display Name', detail.displayName),
                const Divider(),
                _buildTile('Faculty / Program', detail.faculty),
                const Divider(),
                _buildTile('Semester', 'Semester ${detail.semester}'),
                const Divider(),
                _buildTile('Institution', '${detail.institutionName} (ID: ${detail.institutionId})'),
                const Divider(),
                _buildTile('Created By', detail.createdBy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _AddStudentSheet extends StatefulWidget {
  final List<ClassStudentModel> unassignedStudents;
  final Function(int studentId) onAdd;

  const _AddStudentSheet({required this.unassignedStudents, required this.onAdd});

  @override
  State<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<_AddStudentSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.unassignedStudents
        .where((s) => s.fullName.toLowerCase().contains(_query.toLowerCase()) || s.email.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Add Unassigned Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search unassigned student name or email...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No unassigned students found.'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDBEAFE),
                          child: Text(s.fullName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                        ),
                        title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(s.email),
                        trailing: ElevatedButton(
                          onPressed: () => widget.onAdd(s.studentId),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                          child: const Text('Add', style: TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
