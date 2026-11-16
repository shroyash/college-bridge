import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bridge_mobile/features/subjects/domain/entities/teacher_assignment.dart';
import 'package:bridge_mobile/features/admin_users/domain/entities/user_profile.dart';
import 'package:bridge_mobile/features/admin_users/presentation/controllers/manage_users_providers.dart';

class TeacherDetailsDialog extends ConsumerWidget {
  final UserProfile teacher;

  const TeacherDetailsDialog({super.key, required this.teacher});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = teacher.name.isNotEmpty
        ? teacher.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'T';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: Text(
                    initials.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        teacher.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: teacher.isActive
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          teacher.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: teacher.isActive
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Faculty Member',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Assigned Subjects',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            if (teacher.teacherId != null)
              FutureBuilder<List<TeacherAssignment>>(
                future: ref
                    .read(manageTeacherAssignmentsUseCaseProvider)
                    .getTeacherAssignments(teacher.teacherId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No subjects assigned',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    );
                  }
                  final assignments = snapshot.data ?? [];
                  if (assignments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No subjects assigned',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    );
                  }
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: assignments.length,
                      itemBuilder: (context, index) {
                        final item = assignments[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.bookmark_outline,
                              color: Color(0xFF2563EB), size: 20),
                          title: Text(
                            item.subjectName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text('${item.faculty ?? "Faculty"} • Semester ${item.semester ?? 1}'),
                        );
                      },
                    ),
                  );
                },
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No teacher profile ID linked',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(teacher.isActive ? 'Suspend Teacher' : 'Activate Teacher'),
                        content: Text(
                            'Are you sure you want to ${teacher.isActive ? "suspend" : "activate"} ${teacher.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(teacher.isActive ? 'Suspend' : 'Activate'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final notifier = ref.read(manageUsersNotifierProvider.notifier);
                      final success = teacher.isActive
                          ? await notifier.suspendUser(teacher.userId)
                          : await notifier.activateUser(teacher.userId);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Teacher ${teacher.isActive ? "suspended" : "activated"} successfully.'
                                  : 'Failed to update teacher status.',
                            ),
                            backgroundColor: success
                                ? (teacher.isActive ? Colors.red : Colors.green)
                                : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    teacher.isActive ? Icons.block : Icons.check_circle_outline,
                    size: 16,
                    color: teacher.isActive ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                  label: Text(
                    teacher.isActive ? 'Suspend' : 'Activate',
                    style: TextStyle(
                      color: teacher.isActive ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: BorderSide(
                      color: teacher.isActive ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
