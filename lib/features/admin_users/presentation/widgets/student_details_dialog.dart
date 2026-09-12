import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/domain/entities/subject.dart';
import '../../domain/entities/user_profile.dart';
import '../controllers/manage_users_providers.dart';

class StudentDetailsDialog extends ConsumerWidget {
  final UserProfile student;

  const StudentDetailsDialog({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    student.name.isNotEmpty
                        ? student.name.substring(0, 2).toUpperCase()
                        : 'ST',
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
                        student.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        student.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: student.isActive
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          student.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: student.isActive
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
            Text(
              'Faculty: ${student.studentDetails?.faculty ?? "General Science"}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Semester: ${student.studentDetails?.semester ?? "N/A"}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enrolled Classes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Subject>>(
              future: ref
                  .read(getStudentSubjectsUseCaseProvider)
                  .call(student.userId),
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
                      'No enrollment',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  );
                }
                final subjects = snapshot.data ?? [];
                if (subjects.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No enrollment',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  );
                }
                return Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final sub = subjects[index];
                      final codeText = sub.code != null && sub.code!.isNotEmpty ? ' (${sub.code})' : '';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.school,
                            color: Color(0xFF2563EB), size: 20),
                        title: Text(
                          '${sub.name}$codeText',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text('${sub.programName} • ${sub.creditHours} Credits'),
                      );
                    },
                  ),
                );
              },
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
                        title: Text(student.isActive ? 'Suspend Student' : 'Activate Student'),
                        content: Text(
                            'Are you sure you want to ${student.isActive ? "suspend" : "activate"} ${student.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(student.isActive ? 'Suspend' : 'Activate'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final notifier = ref.read(manageUsersNotifierProvider.notifier);
                      final success = student.isActive
                          ? await notifier.suspendUser(student.userId)
                          : await notifier.activateUser(student.userId);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Student ${student.isActive ? "suspended" : "activated"} successfully.'
                                  : 'Failed to update student status.',
                            ),
                            backgroundColor: success
                                ? (student.isActive ? Colors.red : Colors.green)
                                : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    student.isActive ? Icons.block : Icons.check_circle_outline,
                    size: 16,
                    color: student.isActive ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                  label: Text(
                    student.isActive ? 'Suspend' : 'Activate',
                    style: TextStyle(
                      color: student.isActive ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: BorderSide(
                      color: student.isActive ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
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
