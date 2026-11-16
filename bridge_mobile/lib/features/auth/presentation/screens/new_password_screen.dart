import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/clickable.dart';

import '../controllers/forgot_password_providers.dart';
import '../controllers/forgot_password_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String verificationToken;
  final VoidCallback onBack;
  final VoidCallback onPasswordReset;

  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.verificationToken,
    required this.onBack,
    required this.onPasswordReset,
  });

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Password strength
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase =>
      _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));

  double get _strengthValue {
    int count = [_hasMinLength, _hasUppercase, _hasNumber]
        .where((b) => b)
        .length;
    return count / 3;
  }

  Color get _strengthColor {
    if (_strengthValue < 0.4) return const Color(0xFFEF4444);
    if (_strengthValue < 0.8) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String get _strengthLabel {
    if (_strengthValue < 0.4) return 'Weak';
    if (_strengthValue < 0.8) return 'Fair';
    return 'Strong';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(forgotPasswordNotifierProvider.notifier).resetPassword(
          email: widget.email,
          verificationToken: widget.verificationToken,
          newPassword: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForgotPasswordState>(forgotPasswordNotifierProvider, (_, next) {
      if (next is ForgotPasswordResetSuccess) {
        widget.onPasswordReset();
        ref.read(forgotPasswordNotifierProvider.notifier).reset();
      } else if (next is ForgotPasswordFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        ref.read(forgotPasswordNotifierProvider.notifier).reset();
      }
    });

    final state = ref.watch(forgotPasswordNotifierProvider);
    final isLoading = state is ForgotPasswordLoading;

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
                Clickable(
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

                const SizedBox(height: 8),
                const Text(
                  'New Password',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Heading ──
                const Text(
                  'Create New Password',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your new password must be different from previous passwords.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // ── New Password field ──
                AuthTextField(
                  label: 'New Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Minimum 8 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // ── Strength indicator ──
                if (_passwordController.text.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text(
                        'PASSWORD STRENGTH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _strengthLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _strengthColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _strengthValue,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_strengthColor),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Confirm Password field ──
                AuthTextField(
                  label: 'Confirm New Password',
                  hint: '••••••••',
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Requirements card ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PASSWORD REQUIREMENTS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _RequirementRow(
                          met: _hasMinLength,
                          label: 'Minimum 8 characters'),
                      const SizedBox(height: 6),
                      _RequirementRow(
                          met: _hasUppercase,
                          label: 'At least one uppercase letter'),
                      const SizedBox(height: 6),
                      _RequirementRow(
                          met: _hasNumber,
                          label: 'Include at least one number'),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Update button ──
                AuthButton(
                  label: 'Update Password',
                  isLoading: isLoading,
                  trailingIcon: Icons.lock_rounded,
                  onPressed: _onUpdate,
                ),

                const SizedBox(height: 32),

                // ── Support link ──
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Having trouble? ',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      Clickable(
                        onTap: () {},
                        child: const Text(
                          'Contact IT Support',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single password requirement row with a check/circle icon.
class _RequirementRow extends StatelessWidget {
  final bool met;
  final String label;

  const _RequirementRow({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: met ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            color: met ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
