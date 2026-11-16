import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bridge_mobile/features/dashboard/presentation/controllers/dashboard_providers.dart';
import 'package:bridge_mobile/features/dashboard/presentation/controllers/dashboard_state.dart';
import 'package:bridge_mobile/features/dashboard/domain/entities/subject.dart';
import '../controllers/doubt_providers.dart';

class AskDoubtDialog extends ConsumerStatefulWidget {
  final int? initialSubjectId;
  final String? initialSubjectName;

  const AskDoubtDialog({
    super.key,
    this.initialSubjectId,
    this.initialSubjectName,
  });

  @override
  ConsumerState<AskDoubtDialog> createState() => _AskDoubtDialogState();
}

class _AskDoubtDialogState extends ConsumerState<AskDoubtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();

  int? _selectedSubjectId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubjectId == null || _selectedSubjectId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an enrolled subject'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ds = ref.read(doubtRemoteDataSourceProvider);
      await ds.createDoubt(
        subjectId: _selectedSubjectId!,
        question: _questionController.text.trim(),
      );

      ref.invalidate(doubtsListProvider);
      ref.invalidate(subjectDoubtSummaryProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doubt asked successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post doubt: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(studentDashboardNotifierProvider);

    List<Subject> enrolledSubjects = [];
    if (dashboardState is DashboardSuccess<List<Subject>>) {
      enrolledSubjects = dashboardState.data;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.help_outline, color: Color(0xFF2563EB), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Ask a Doubt',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Subject Dropdown
              const Text(
                'SUBJECT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              if (widget.initialSubjectId != null && widget.initialSubjectId! > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    widget.initialSubjectName ?? 'Subject #${widget.initialSubjectId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                )
              else
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: DropdownButtonFormField<int>(
                  initialValue: _selectedSubjectId,
                  decoration: InputDecoration(
                    hintText: enrolledSubjects.isEmpty
                        ? 'No enrolled subjects found'
                        : 'Select enrolled subject',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: enrolledSubjects.map((sub) {
                    return DropdownMenuItem<int>(
                      value: sub.subjectId,
                      child: Text(
                        sub.name,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedSubjectId = val);
                  },
                  validator: (val) =>
                      val == null ? 'Subject is required' : null,
                ),
                ),
              const SizedBox(height: 16),

              // Question Input
              const Text(
                'QUESTION / DOUBT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _questionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your doubt here... (e.g. What is polymorphism in Java?)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Question cannot be empty';
                  }
                  if (val.trim().length < 5) {
                    return 'Please describe your doubt in at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Post Doubt',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
