import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/forgot_password_providers.dart';
import '../controllers/forgot_password_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_info_card.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final void Function(String email) onOtpSent;

  const ForgotPasswordScreen({
    super.key,
    required this.onBack,
    required this.onOtpSent,
  });

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _iconScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _onSendCode() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(forgotPasswordNotifierProvider.notifier).sendOtp(
          email: _emailController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForgotPasswordState>(forgotPasswordNotifierProvider, (_, next) {
      if (next is ForgotPasswordOtpSent) {
        widget.onOtpSent(next.email);
        ref.read(forgotPasswordNotifierProvider.notifier).reset();
      } else if (next is ForgotPasswordFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

                const SizedBox(height: 8),

                // ── Page label ──
                const Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Animated icon badge ──
                Center(
                  child: ScaleTransition(
                    scale: _iconScale,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.30),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Heading ──
                const Center(
                  child: Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Enter your registered email address to\nreceive a verification code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Email field ──
                AuthTextField(
                  label: 'Email Address',
                  hint: 'e.g. student@college.edu',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ── Send Code button ──
                AuthButton(
                  label: 'Send Code',
                  isLoading: isLoading,
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: _onSendCode,
                ),

                const SizedBox(height: 28),

                // ── Security tip card ──
                const AuthInfoCard(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: Color(0xFF7C3AED),
                  iconBgColor: Color(0xFFEDE9FE),
                  title: 'Academic Security Tip',
                  description:
                      'Use your official institutional email for faster verification. '
                      'Codes expire in 10 minutes for your protection.',
                ),

                const SizedBox(height: 40),

                // ── Sign in link ──
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Remember password? ',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                      GestureDetector(
                        onTap: widget.onBack,
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

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
