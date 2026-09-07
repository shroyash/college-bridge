import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/error/auth_exceptions.dart';
import '../controllers/auth_providers.dart';
import '../controllers/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../domain/entities/auth_user.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToRegister;
  final VoidCallback onLoginSuccess;
  final VoidCallback onBack;
  final VoidCallback onForgotPassword;
  final void Function(AuthUser user)? onLoginSuccessWithUser;
  // Called when institution is rejected — user can try re-registration
  final VoidCallback? onNavigateToInstitutionRegister;

  const LoginScreen({
    super.key,
    required this.onNavigateToRegister,
    required this.onLoginSuccess,
    required this.onBack,
    required this.onForgotPassword,
    this.onLoginSuccessWithUser,
    this.onNavigateToInstitutionRegister,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _institutionCodeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _institutionCodeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authNotifierProvider.notifier).login(
          institutionCode: _institutionCodeCtrl.text.trim().toUpperCase(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthSuccess) {
        if (widget.onLoginSuccessWithUser != null) {
          widget.onLoginSuccessWithUser!(next.user);
        } else {
          widget.onLoginSuccess();
        }
      }
      // AuthLoginFailure is handled inline via ref.watch below
      // Generic errors still use snackbar
      if (next is AuthFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        ref.read(authNotifierProvider.notifier).reset();
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final loginFailure =
        authState is AuthLoginFailure ? authState : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // ── Back ──
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Welcome Back',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Login to your institution account',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 28),

              // ── Login failure banners (distinct per reason) ──
              if (loginFailure != null) ...[
                _LoginFailureBanner(
                  failure: loginFailure,
                  onDismiss: () =>
                      ref.read(authNotifierProvider.notifier).reset(),
                  onResubmit:
                      widget.onNavigateToInstitutionRegister,
                ),
                const SizedBox(height: 20),
              ],

              // ── Form ──
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthTextField(
                      label: 'Institution Code (Optional for Super Admin)',
                      hint: 'e.g. TU-KTM',
                      controller: _institutionCodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'Email',
                      hint: 'Enter your email',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                            .hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: widget.onForgotPassword,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 0),
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AuthButton(
                      label: 'LOGIN',
                      isLoading: isLoading,
                      onPressed: _onLogin,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: Color(0xFFE2E8F0), thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 13)),
                  ),
                  Expanded(
                      child: Divider(
                          color: Color(0xFFE2E8F0), thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Register institution link ──
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: widget.onNavigateToInstitutionRegister,
                      child: Text(
                        'Register a new institution →',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF7C3AED),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF64748B))),
                        GestureDetector(
                          onTap: widget.onNavigateToRegister,
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF2563EB),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-reason failure banners
// ─────────────────────────────────────────────────────────────────────────────

class _LoginFailureBanner extends StatelessWidget {
  final AuthLoginFailure failure;
  final VoidCallback onDismiss;
  final VoidCallback? onResubmit;

  const _LoginFailureBanner({
    required this.failure,
    required this.onDismiss,
    this.onResubmit,
  });

  @override
  Widget build(BuildContext context) {
    return switch (failure.reason) {
      LoginFailureReason.institutionPending => _BannerCard(
          color: const Color(0xFFFEF3C7),
          borderColor: const Color(0xFFFCD34D),
          iconColor: const Color(0xFFF59E0B),
          icon: Icons.hourglass_top_rounded,
          title: 'Registration Under Review',
          message:
              'Your institution\'s registration is pending approval. '
              'We\'ll notify you by email once reviewed.',
          onDismiss: onDismiss,
        ),
      LoginFailureReason.institutionRejected => _BannerCard(
          color: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFCA5A5),
          iconColor: const Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
          title: 'Registration Rejected',
          message: failure.rejectionReason ??
              failure.message,
          onDismiss: onDismiss,
          action: onResubmit != null
              ? _BannerAction(
                  label: 'Resubmit Application',
                  color: const Color(0xFFEF4444),
                  onTap: onResubmit!,
                )
              : null,
        ),
      LoginFailureReason.institutionSuspended => _BannerCard(
          color: const Color(0xFFF5F3FF),
          borderColor: const Color(0xFFDDD6FE),
          iconColor: const Color(0xFF7C3AED),
          icon: Icons.block_rounded,
          title: 'Institution Suspended',
          message:
              'Your institution\'s account has been suspended. '
              'Please contact support for assistance.',
          onDismiss: onDismiss,
        ),
      LoginFailureReason.userSuspended => _BannerCard(
          color: const Color(0xFFFFF7ED),
          borderColor: const Color(0xFFFED7AA),
          iconColor: const Color(0xFFF97316),
          icon: Icons.person_off_rounded,
          title: 'Account Suspended',
          message:
              'Your personal account has been suspended. '
              'Contact your institution administrator.',
          onDismiss: onDismiss,
        ),
      LoginFailureReason.userInactive ||
      LoginFailureReason.invalidCredentials ||
      LoginFailureReason.unknown =>
        _BannerCard(
          color: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFCA5A5),
          iconColor: const Color(0xFFEF4444),
          icon: Icons.error_outline_rounded,
          title: 'Login Failed',
          message: failure.message.isNotEmpty
              ? failure.message
              : 'Invalid email or password. Please try again.',
          onDismiss: onDismiss,
        ),
    };
  }
}

class _BannerCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onDismiss;
  final _BannerAction? action;

  const _BannerCard({
    required this.color,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.message,
    required this.onDismiss,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close_rounded,
                    size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF374151),
              height: 1.5,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: action!.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: action!.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  action!.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BannerAction {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BannerAction({
    required this.label,
    required this.color,
    required this.onTap,
  });
}
