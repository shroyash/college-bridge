import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/academic_management_providers.dart';
import '../../data/models/academic_class_model.dart';
import 'class_details_screen.dart';
import '../../../admin_users/presentation/controllers/manage_users_providers.dart';
import '../../../admin_users/data/models/user_profile_model.dart';

class ManageClassesScreen extends ConsumerStatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  ConsumerState<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends ConsumerState<ManageClassesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AcademicClassModel> _classes = [];
  List<String> _faculties = ['ALL', 'BCA', 'BBA', 'BIM', 'BSC_CSIT', 'BHM'];
  String _selectedFaculty = 'ALL';
  int? _selectedSemester;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFacultiesAndClasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFacultiesAndClasses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dataSource = ref.read(academicAdminRemoteDataSourceProvider);
      final list = await dataSource.getSupportedFaculties();
      if (list.isNotEmpty) {
        setState(() {
          _faculties = ['ALL', ...list];
        });
      }
      await _fetchClasses();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchClasses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dataSource = ref.read(academicAdminRemoteDataSourceProvider);
      final classes = await dataSource.getAcademicClassesFiltered(
        faculty: _selectedFaculty,
        semester: _selectedSemester,
        search: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _classes = classes;
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

  Future<void> _showAddClassDialog() async {
    String faculty = _selectedFaculty != 'ALL' ? _selectedFaculty : (_faculties.length > 1 ? _faculties[1] : 'BCA');
    int semester = 1;
    final nameController = TextEditingController(text: '$faculty 1st Semester');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create New Academic Class', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Faculty/Program:'),
              const SizedBox(height: 6),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: DropdownButtonFormField<String>(
                  initialValue: faculty,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: _faculties
                      .where((f) => f != 'ALL')
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        faculty = val;
                        nameController.text = '$faculty ${semester}th Semester';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text('Select Semester:'),
              const SizedBox(height: 6),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: DropdownButtonFormField<int>(
                  initialValue: semester,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('Semester ${i + 1}'))),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        semester = val;
                        nameController.text = '$faculty ${semester}th Semester';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text('Class Display Name:'),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. BCA Semester 1'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final dataSource = ref.read(academicAdminRemoteDataSourceProvider);
                  await dataSource.createAcademicClass(
                    faculty: faculty,
                    semester: semester,
                    displayName: nameController.text.trim(),
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Class created successfully!'), backgroundColor: Color(0xFF16A34A)),
                    );
                    _fetchClasses();
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Create Class', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickAssignTeacher(AcademicClassModel academicClass) async {
    try {
      final adminUserDs = ref.read(adminUserRemoteDataSourceProvider);
      final teachers = await adminUserDs.filterUsers(role: 'TEACHER', status: 'ACTIVE');

      if (!mounted) return;

      UserProfileModel? selectedTeacher;
      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            title: Text('Assign Teacher to ${academicClass.displayName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select designated primary class teacher:'),
                const SizedBox(height: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: DropdownButtonFormField<UserProfileModel>(
                    initialValue: selectedTeacher,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    hint: const Text('Choose teacher...'),
                    items: teachers.map((t) => DropdownMenuItem(value: t, child: Text('${t.name} (${t.email})'))).toList(),
                    onChanged: (val) => setModalState(() => selectedTeacher = val),
                  ),
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
                          await academicDs.assignClassTeacher(academicClass.classId, selectedTeacher!.userId);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('${selectedTeacher!.name} designated as Class Teacher for ${academicClass.displayName}.')),
                            );
                            _fetchClasses();
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
        title: const Text(
          'Manage Classes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchClasses,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Header
          Container(
            color: const Color(0xFF1E40AF),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _fetchClasses(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search class name or faculty...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              _fetchClasses();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // Faculty Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _faculties.map((fac) {
                      final isSelected = _selectedFaculty == fac;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(fac),
                          selected: isSelected,
                          selectedColor: Colors.white,
                          backgroundColor: const Color(0xFF1D4ED8),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF1E40AF) : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (sel) {
                            if (sel) {
                              setState(() => _selectedFaculty = fac);
                              _fetchClasses();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Semester Filter Dropdown Strip
                Row(
                  children: [
                    const Text('Semester: ', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: DropdownButton<int?>(
                        value: _selectedSemester,
                        dropdownColor: const Color(0xFF1E40AF),
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All Semesters')),
                          ...List.generate(
                            8,
                            (i) => DropdownMenuItem<int?>(
                              value: i + 1,
                              child: Text('Semester ${i + 1}'),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedSemester = val);
                          _fetchClasses();
                        },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Class Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchClasses, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _classes.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.class_outlined, size: 64, color: Color(0xFF94A3B8)),
                                  const SizedBox(height: 16),
                                  const Text('No Academic Classes Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 8),
                                  const Text('Create classes for your institution to manage student cohorts and class teachers.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _showAddClassDialog,
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    label: const Text('Create First Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _classes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final ac = _classes[index];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDBEAFE),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${ac.faculty} • Sem ${ac.semester}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${ac.totalStudents} Enrolled Students',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        ac.displayName,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.school_outlined, size: 16, color: Color(0xFF64748B)),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Class Teacher: ${ac.classTeacherName ?? "Unassigned"}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: ac.classTeacherName != null ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                              fontWeight: ac.classTeacherName != null ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => _quickAssignTeacher(ac),
                                            icon: const Icon(Icons.person_add_outlined, size: 16),
                                            label: const Text('Assign Teacher'),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ClassDetailsScreen(
                                                    classId: ac.classId,
                                                    className: ac.displayName,
                                                  ),
                                                ),
                                              ).then((_) => _fetchClasses());
                                            },
                                            icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                                            label: const Text('View Class Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassDialog,
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
