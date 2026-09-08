import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../institution_admin/data/models/academic_level_model.dart';
import '../../../institution_admin/data/models/academic_program_model.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../controllers/auth_providers.dart';
import '../controllers/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_info_card.dart';
import '../widgets/auth_text_field.dart';

import 'otp_verification_screen.dart';

/// Register Screen — normalized academic hierarchy version.
/// • Institution Code → loads Programs → loads Levels → picks levelId
class RegisterScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToLogin;
  final VoidCallback onRegisterSuccess;
  final VoidCallback onBack;

  const RegisterScreen({
    super.key,
    required this.onNavigateToLogin,
    required this.onRegisterSuccess,
    required this.onBack,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _institutionCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _sendingOtp = false;

  // Hierarchy state
  List<AcademicProgramModel> _programs = [];
  List<AcademicLevelModel> _levels = [];
  AcademicProgramModel? _selectedProgram;
  AcademicLevelModel? _selectedLevel;
  bool _loadingPrograms = false;
  bool _loadingLevels = false;
  String? _hierarchyError;

  @override
  void dispose() {
    _institutionCodeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  AuthRemoteDataSource get _authDs {
    return ref.read(authRemoteDataSourceProvider);
  }

  Future<void> _loadPrograms() async {
    final code = _institutionCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _hierarchyError = 'Please enter an institution code first.';
      });
      return;
    }
    setState(() {
      _loadingPrograms = true;
      _programs = [];
      _levels = [];
      _selectedProgram = null;
      _selectedLevel = null;
      _hierarchyError = null;
    });
    try {
      final programs = await _authDs.getPublicPrograms(code);
      setState(() {
        _programs = programs;
        _loadingPrograms = false;
        if (programs.isEmpty) {
          _hierarchyError = 'No academic programs found for institution code "$code".';
        }
      });
    } catch (e) {
      setState(() {
        _hierarchyError = e.toString().replaceAll('Exception: ', '');
        _loadingPrograms = false;
      });
    }
  }

  Future<void> _loadLevels(int programId) async {
    setState(() {
      _loadingLevels = true;
      _levels = [];
      _selectedLevel = null;
    });
    try {
      final levels = await _authDs.getPublicLevels(programId);
      setState(() {
        _levels = levels;
        _loadingLevels = false;
        if (levels.isEmpty) {
          _hierarchyError = 'No levels found for this program.';
        }
      });
    } catch (e) {
      setState(() {
        _hierarchyError = e.toString().replaceAll('Exception: ', '');
        _loadingLevels = false;
      });
    }
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLevel == null) {
      _showError('Please select your program and level.');
      return;
    }

    final institutionCode = _institutionCodeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final levelId = _selectedLevel!.levelId;

    setState(() => _sendingOtp = true);

    try {
      await _authDs.sendRegistrationOtp(email: email);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            title: 'Verify Registration Email',
            subtitle: 'Please enter the 6-digit verification code sent to ',
            onBack: () => Navigator.pop(context),
            onVerifyCustom: (ref, otpCode) async {
              await _authDs.verifyRegistrationOtp(
                email: email,
                code: otpCode,
              );
              await ref.read(authNotifierProvider.notifier).register(
                    institutionCode: institutionCode,
                    name: name,
                    email: email,
                    password: password,
                    levelId: levelId,
                  );
            },
            onResendCustom: (ref) async {
              await _authDs.sendRegistrationOtp(email: email);
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _sendingOtp = false);
      }
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
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthSuccess) {
        widget.onRegisterSuccess();
      } else if (next is AuthFailure) {
        _showError(next.message);
        ref.read(authNotifierProvider.notifier).reset();
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = _sendingOtp || authState is AuthLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Back button ──
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Heading ──
                const Text(
                  'Create Student Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Join your classroom and start learning.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Institution Code ──
                AuthTextField(
                  label: 'Institution Code',
                  hint: 'e.g. TU-KTM',
                  controller: _institutionCodeController,
                  textCapitalization: TextCapitalization.characters,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      final code = _institutionCodeController.text.trim();
                      if (code.isNotEmpty) _loadPrograms();
                    },
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Institution code is required';
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    final code = _institutionCodeController.text.trim();
                    if (code.isNotEmpty) _loadPrograms();
                  },
                ),

                const SizedBox(height: 18),

                // ── Full Name ──
                AuthTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  suffixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFFB0BAC8),
                    size: 20,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length > 100) return 'Name too long';
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ── Email ──
                AuthTextField(
                  label: 'Email Address',
                  hint: 'Enter your college email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  suffixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: Color(0xFFB0BAC8),
                    size: 20,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ── Password ──
                AuthTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.lock_outline_rounded
                          : Icons.lock_open_rounded,
                      color: const Color(0xFFB0BAC8),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ── Program Selector ──
                _buildDropdownSection<AcademicProgramModel>(
                  label: 'PROGRAM',
                  isLoading: _loadingPrograms,
                  hint: _programs.isEmpty
                      ? 'Enter institution code and tap 🔍 first'
                      : 'Select your program',
                  value: _selectedProgram,
                  items: _programs
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              '${p.name} (${p.code})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProgram = value;
                      _selectedLevel = null;
                      _levels = [];
                    });
                    if (value != null) _loadLevels(value.programId);
                  },
                ),

                const SizedBox(height: 18),

                // ── Level Selector ──
                _buildDropdownSection<AcademicLevelModel>(
                  label: 'LEVEL / SEMESTER',
                  isLoading: _loadingLevels,
                  hint: _selectedProgram == null
                      ? 'Select a program first'
                      : _levels.isEmpty
                          ? 'No levels available'
                          : 'Select your level',
                  value: _selectedLevel,
                  items: _levels
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(
                              l.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: _selectedProgram == null || _levels.isEmpty
                      ? null
                      : (AcademicLevelModel? value) => setState(() => _selectedLevel = value),
                ),

                if (_hierarchyError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _hierarchyError!,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                  ),
                ],

                const SizedBox(height: 22),

                // ── Institutional Onboarding card ──
                const AuthInfoCard(
                  icon: Icons.verified_user_outlined,
                  iconColor: Color(0xFF2563EB),
                  iconBgColor: Color(0xFFDBEAFE),
                  title: 'Institutional Onboarding',
                  description:
                      'By registering, you\'ll gain access to the secure College Bridge portal for automated course tracking and collaborative tools.',
                ),

                const SizedBox(height: 24),

                // ── Create Account button ──
                AuthButton(
                  label: 'CREATE ACCOUNT',
                  trailingIcon: Icons.arrow_forward_rounded,
                  isLoading: isLoading,
                  onPressed: _onRegister,
                ),

                const SizedBox(height: 20),

                // ── Sign In link ──
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onNavigateToLogin,
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSection<T>({
    required String label,
    required bool isLoading,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        if (isLoading)
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          DropdownButtonFormField<T>(
            initialValue: value,
            hint: Text(
              hint,
              style: const TextStyle(
                color: Color(0xFFB0BAC8),
                fontSize: 14,
              ),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
            ),
            items: items,
            onChanged: onChanged,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF94A3B8),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
      ],
    );
  }
}
