import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../academics/data/models/academic_level_model.dart';
import '../../../students/data/datasources/student_admin_remote_datasource.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../../data/models/create_notification_request_model.dart';
import '../../domain/entities/notification_target_type.dart';
import '../controllers/notification_providers.dart';
import '../widgets/searchable_selection_field.dart';
import '../widgets/student_multi_selection_field.dart';

class BroadcastNotificationScreen extends ConsumerStatefulWidget {
  const BroadcastNotificationScreen({super.key});

  @override
  ConsumerState<BroadcastNotificationScreen> createState() =>
      _BroadcastNotificationScreenState();
}

class _BroadcastNotificationScreenState
    extends ConsumerState<BroadcastNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _targetIdController = TextEditingController();
  final Map<int, StudentSummary> _selectedStudents = {};

  NotificationTargetType _selectedTarget = NotificationTargetType.INSTITUTION;
  String? _userRole;
  SubjectModel? _selectedSubject;
  AcademicLevelModel? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final storage = ref.read(secureStorageProvider);
    final role = await storage.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
        if (role == 'TEACHER') {
          _selectedTarget = NotificationTargetType.CLASS;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _targetIdController.dispose();
    super.dispose();
  }

  List<NotificationTargetType> get _availableTargets {
    if (_userRole == 'TEACHER') {
      return [
        NotificationTargetType.CLASS,
        NotificationTargetType.SUBJECT,
        NotificationTargetType.USERS,
      ];
    }
    return [
      NotificationTargetType.INSTITUTION,
      NotificationTargetType.CLASS,
      NotificationTargetType.SUBJECT,
      NotificationTargetType.USERS,
    ];
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    int? targetId;
    if (_selectedTarget == NotificationTargetType.CLASS) {
      if (_selectedLevel == null) {
        SnackBarHelper.showError(context, 'Please select an Academic Level / Class');
        return;
      }
      targetId = _selectedLevel!.levelId;
    } else if (_selectedTarget == NotificationTargetType.SUBJECT) {
      if (_selectedSubject == null) {
        SnackBarHelper.showError(context, 'Please select a Subject');
        return;
      }
      targetId = _selectedSubject!.subjectId;
    }

    List<int>? userIds;
    if (_selectedTarget == NotificationTargetType.USERS) {
      if (_selectedStudents.isEmpty) {
        SnackBarHelper.showError(context, 'Please select at least one student');
        return;
      }
      userIds = _selectedStudents.keys.toList();
    }

    final idempotencyKey =
        'broadcast_${DateTime.now().millisecondsSinceEpoch}_${_titleController.text.hashCode}';

    final request = CreateNotificationRequestModel(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      targetType: _selectedTarget,
      targetId: targetId,
      userIds: userIds,
      idempotencyKey: idempotencyKey,
    );

    final success = await ref
        .read(notificationNotifierProvider.notifier)
        .broadcastNotification(request);

    if (mounted) {
      if (success) {
        SnackBarHelper.showSuccess(context, 'Broadcast notification dispatched!');
        Navigator.pop(context);
      } else {
        final err = ref.read(notificationNotifierProvider).errorMessage;
        SnackBarHelper.showError(context, err ?? 'Failed to send notification');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Send Broadcast Notice',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Broadcasting will send in-app inbox notices and mobile push notifications to the selected audience.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E40AF),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Notice Title *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'e.g. Midterm Examination Schedule Released',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Message Body
              const Text(
                'Notice Content *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyController,
                maxLines: 5,
                maxLength: 4000,
                decoration: InputDecoration(
                  hintText: 'Enter complete announcement details...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Notice content is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Audience
              const Text(
                'Target Audience *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<NotificationTargetType>(
                    value: _selectedTarget,
                    isExpanded: true,
                    items: _availableTargets.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null && val != _selectedTarget) {
                        setState(() {
                          _selectedTarget = val;
                          _selectedSubject = null;
                          _selectedLevel = null;
                          _targetIdController.clear();
                          _selectedStudents.clear();
                        });
                      }
                    },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Conditional target fields
              if (_selectedTarget == NotificationTargetType.CLASS) ...[
                SearchableSelectionField<AcademicLevelModel>(
                  label: 'Academic Level / Class',
                  hintText: 'Select an Academic Level / Class...',
                  asyncItems: ref.watch(notificationLevelListProvider(_userRole)),
                  selectedItem: _selectedLevel,
                  onSelected: (level) {
                    setState(() {
                      _selectedLevel = level;
                      _targetIdController.text = level?.levelId.toString() ?? '';
                    });
                  },
                  titleBuilder: (level) => level.name.isNotEmpty
                      ? (level.programName.isNotEmpty
                          ? '${level.programName} – ${level.name}'
                          : level.name)
                      : 'Level ${level.levelId}',
                  subtitleBuilder: (level) {
                    final parts = <String>[];
                    if (level.programCode.isNotEmpty) {
                      parts.add('Program: ${level.programCode}');
                    } else if (level.programName.isNotEmpty) {
                      parts.add(level.programName);
                    }
                    if (level.type.isNotEmpty) {
                      parts.add(level.type);
                    }
                    if (level.levelNumber > 0) {
                      parts.add('Level #${level.levelNumber}');
                    }
                    return parts.join(' • ');
                  },
                  searchMatcher: (level, q) {
                    final query = q.toLowerCase();
                    return level.name.toLowerCase().contains(query) ||
                        level.programName.toLowerCase().contains(query) ||
                        level.programCode.toLowerCase().contains(query) ||
                        level.type.toLowerCase().contains(query) ||
                        level.levelNumber.toString().contains(query);
                  },
                  onRetry: () =>
                      ref.refresh(notificationLevelListProvider(_userRole)),
                ),
                const SizedBox(height: 16),
              ],

              if (_selectedTarget == NotificationTargetType.SUBJECT) ...[
                SearchableSelectionField<SubjectModel>(
                  label: 'Subject',
                  hintText: 'Select a Subject...',
                  asyncItems: ref.watch(notificationSubjectListProvider(_userRole)),
                  selectedItem: _selectedSubject,
                  onSelected: (subject) {
                    setState(() {
                      _selectedSubject = subject;
                      _targetIdController.text =
                          subject?.subjectId.toString() ?? '';
                    });
                  },
                  titleBuilder: (sub) => sub.name,
                  subtitleBuilder: (sub) {
                    final parts = <String>[];
                    if (sub.code != null && sub.code!.isNotEmpty) {
                      parts.add('Code: ${sub.code}');
                    }
                    if (sub.programName.isNotEmpty) {
                      parts.add(sub.programName);
                    }
                    if (sub.levelName.isNotEmpty) {
                      parts.add(sub.levelName);
                    }
                    return parts.join(' • ');
                  },
                  searchMatcher: (sub, q) {
                    final query = q.toLowerCase();
                    return sub.name.toLowerCase().contains(query) ||
                        (sub.code?.toLowerCase().contains(query) ?? false) ||
                        sub.programName.toLowerCase().contains(query) ||
                        sub.levelName.toLowerCase().contains(query);
                  },
                  onRetry: () =>
                      ref.refresh(notificationSubjectListProvider(_userRole)),
                ),
                const SizedBox(height: 16),
              ],

              if (_selectedTarget == NotificationTargetType.USERS) ...[
                StudentMultiSelectionField(
                  selectedStudents: _selectedStudents,
                  onSelectionChanged: (updated) {
                    setState(() {
                      _selectedStudents
                        ..clear()
                        ..addAll(updated);
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Send Broadcast Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
