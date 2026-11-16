import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bridge_mobile/core/widgets/clickable.dart';
import 'package:bridge_mobile/features/institutions/domain/entities/institution_entities.dart';
import 'package:bridge_mobile/features/institutions/presentation/controllers/institution_providers.dart';
import 'package:bridge_mobile/features/institutions/presentation/controllers/institution_state.dart';
import 'registration_submitted_screen.dart';

class InstitutionRegistrationScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final void Function(InstitutionRegistrationResult)? onSuccess;

  const InstitutionRegistrationScreen({
    super.key,
    required this.onBack,
    this.onSuccess,
  });

  @override
  ConsumerState<InstitutionRegistrationScreen> createState() =>
      _InstitutionRegistrationScreenState();
}

class _InstitutionRegistrationScreenState
    extends ConsumerState<InstitutionRegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 — Institution Details
  final _step1Key = GlobalKey<FormState>();
  final _institutionNameCtrl = TextEditingController();
  final _institutionCodeCtrl = TextEditingController();

  // Step 2 — Admin Account
  final _step2Key = GlobalKey<FormState>();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Step 3 — Documents
  final List<PlatformFile> _pickedFiles = [];

  @override
  void dispose() {
    _pageController.dispose();
    _institutionNameCtrl.dispose();
    _institutionCodeCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    bool valid = false;
    if (_currentStep == 0) valid = _step1Key.currentState!.validate();
    if (_currentStep == 1) valid = _step2Key.currentState!.validate();
    if (!valid) return;
    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    if (_currentStep == 0) {
      widget.onBack();
      return;
    }
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null) {
      setState(() {
        for (final f in result.files) {
          if (!_pickedFiles.any((p) => p.name == f.name)) {
            _pickedFiles.add(f);
          }
        }
      });
    }
  }

  void _removeFile(int index) => setState(() => _pickedFiles.removeAt(index));

  Future<void> _submit() async {
    if (_pickedFiles.isEmpty) {
      _showError('Please attach at least one document.');
      return;
    }

    try {
      final List<MapEntry<String, MultipartFile>> docs = [];
      for (final f in _pickedFiles) {
        if (f.bytes != null) {
          docs.add(
            MapEntry(
              f.name,
              MultipartFile.fromBytes(f.bytes!, filename: f.name),
            ),
          );
        } else if (!kIsWeb && f.path != null && f.path!.isNotEmpty) {
          docs.add(
            MapEntry(
              f.name,
              MultipartFile.fromFileSync(f.path!, filename: f.name),
            ),
          );
        } else {
          _showError(
            'Unable to read file ${f.name}. Please re-select the file.',
          );
          return;
        }
      }

      await ref
          .read(institutionRegistrationProvider.notifier)
          .register(
            institutionName: _institutionNameCtrl.text.trim(),
            institutionCode: _institutionCodeCtrl.text.trim().toUpperCase(),
            adminName: _adminNameCtrl.text.trim(),
            adminEmail: _adminEmailCtrl.text.trim(),
            adminPassword: _adminPasswordCtrl.text,
            documents: docs,
          );
    } catch (e) {
      _showError('Failed to prepare documents: ${e.toString()}');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<InstitutionRegistrationState>(institutionRegistrationProvider, (
      _,
      next,
    ) {
      if (next is RegistrationSuccess) {
        if (widget.onSuccess != null) {
          widget.onSuccess!(next.result);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RegistrationSubmittedScreen(
                result: next.result,
                onGoToLogin: widget.onBack,
              ),
            ),
          );
        }
      } else if (next is RegistrationFailure) {
        _showError(next.message);
        ref.read(institutionRegistrationProvider.notifier).reset();
      }
    });

    final state = ref.watch(institutionRegistrationProvider);
    final isLoading = state is RegistrationLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepInstitutionDetails(
                    formKey: _step1Key,
                    nameCtrl: _institutionNameCtrl,
                    codeCtrl: _institutionCodeCtrl,
                  ),
                  _StepAdminAccount(
                    formKey: _step2Key,
                    nameCtrl: _adminNameCtrl,
                    emailCtrl: _adminEmailCtrl,
                    passwordCtrl: _adminPasswordCtrl,
                    confirmCtrl: _confirmPasswordCtrl,
                    obscurePass: _obscurePass,
                    obscureConfirm: _obscureConfirm,
                    onTogglePass: () =>
                        setState(() => _obscurePass = !_obscurePass),
                    onToggleConfirm: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  _StepDocuments(
                    files: _pickedFiles,
                    onPickFiles: _pickDocuments,
                    onRemoveFile: _removeFile,
                  ),
                ],
              ),
            ),
            _buildBottomBar(isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Clickable(
            onTap: _prevStep,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Register Institution',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of 3',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i <= _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : (_currentStep < 2 ? _nextStep : _submit),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            // CHANGED: explicit pointer cursor (basic while loading/disabled)
            enabledMouseCursor: SystemMouseCursors.click,
            disabledMouseCursor: SystemMouseCursors.basic,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  _currentStep < 2 ? 'Continue' : 'Submit Registration',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Step widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StepInstitutionDetails extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController codeCtrl;

  const _StepInstitutionDetails({
    required this.formKey,
    required this.nameCtrl,
    required this.codeCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.business_rounded,
              title: 'Institution Details',
              subtitle: 'Enter your institution\'s basic information',
            ),
            const SizedBox(height: 24),
            _FormField(
              label: 'Institution Name',
              hint: 'e.g. Tribhuvan University',
              controller: nameCtrl,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            _FormField(
              label: 'Institution Code',
              hint: 'e.g. TU-KTM (unique identifier)',
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Code is required';
                if (v.trim().length < 2) return 'Code too short';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The institution code is used by students and teachers to log in. Choose something memorable.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepAdminAccount extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;

  const _StepAdminAccount({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.manage_accounts_rounded,
              title: 'Admin Account',
              subtitle: 'This will be the primary administrator account',
            ),
            const SizedBox(height: 24),
            _FormField(
              label: 'Full Name',
              hint: 'Your name',
              controller: nameCtrl,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            _FormField(
              label: 'Email Address',
              hint: 'admin@institution.edu',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _FormField(
              label: 'Password',
              hint: 'At least 8 characters',
              controller: passwordCtrl,
              obscureText: obscurePass,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF94A3B8),
                  size: 20,
                ),
                onPressed: onTogglePass,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8) return 'Minimum 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _FormField(
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              controller: confirmCtrl,
              obscureText: obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF94A3B8),
                  size: 20,
                ),
                onPressed: onToggleConfirm,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm password';
                if (v != passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDocuments extends StatelessWidget {
  final List<PlatformFile> files;
  final VoidCallback onPickFiles;
  final void Function(int) onRemoveFile;

  const _StepDocuments({
    required this.files,
    required this.onPickFiles,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.upload_file_rounded,
            title: 'Verification Documents',
            subtitle:
                'Upload registration certificate, trade license, or other proof',
          ),
          const SizedBox(height: 24),
          // Upload area
          Clickable(
            onTap: onPickFiles,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2563EB),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      color: Color(0xFF2563EB),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Click to browse files',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PDF, JPG, PNG supported',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (files.isEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'At least one document is required',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
          if (files.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              '${files.length} file${files.length > 1 ? 's' : ''} selected',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            ...files.asMap().entries.map((e) {
              final idx = e.key;
              final f = e.value;
              final ext = f.name.split('.').last.toLowerCase();
              final isImage = ['jpg', 'jpeg', 'png'].contains(ext);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isImage
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isImage
                            ? Icons.image_rounded
                            : Icons.picture_as_pdf_rounded,
                        size: 18,
                        color: isImage
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF97316),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${((f.size) / 1024).toStringAsFixed(1)} KB',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // IconButton already shows the pointer cursor
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      onPressed: () => onRemoveFile(idx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFCBD5E1),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
        ),
      ],
    );
  }
}