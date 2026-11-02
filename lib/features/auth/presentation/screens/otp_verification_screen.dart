import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/clickable.dart';

import '../controllers/forgot_password_providers.dart';
import '../controllers/forgot_password_state.dart';
import '../widgets/auth_button.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final VoidCallback onBack;
  final void Function(String email, String verificationToken)? onOtpVerified;
  final Future<void> Function(WidgetRef ref, String otp)? onVerifyCustom;
  final Future<void> Function(WidgetRef ref)? onResendCustom;
  final String title;
  final String subtitle;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.onBack,
    this.onOtpVerified,
    this.onVerifyCustom,
    this.onResendCustom,
    this.title = 'Verify Email',
    this.subtitle = 'Please enter the 6-digit code sent to your email\naddress ',
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const int _otpLength = 6;
  static const int _resendSeconds = 60;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  late AnimationController _shieldController;
  late Animation<double> _shieldScale;

  int _resendCountdown = _resendSeconds;
  Timer? _resendTimer;
  bool _isCustomLoading = false;

  @override
  void initState() {
    super.initState();
    _shieldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _shieldScale = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _shieldController, curve: Curves.easeInOut),
    );
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendCountdown = _resendSeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown <= 0) {
        t.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shieldController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otp.length == _otpLength;

  void _onVerify() async {
    if (!_isOtpComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter all 6 digits'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (widget.onVerifyCustom != null) {
      setState(() => _isCustomLoading = true);
      try {
        await widget.onVerifyCustom!(ref, _otp);
      } catch (e) {
        if (mounted) {
          final msg = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isCustomLoading = false);
      }
      return;
    }

    ref.read(forgotPasswordNotifierProvider.notifier).verifyOtp(
          email: widget.email,
          code: _otp,
        );
  }

  void _onResend() async {
    if (_resendCountdown > 0) return;
    if (widget.onResendCustom != null) {
      try {
        await widget.onResendCustom!(ref);
        _startResendTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Code resent successfully!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final msg = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to resend code: $msg'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
      return;
    }

    ref
        .read(forgotPasswordNotifierProvider.notifier)
        .sendOtp(email: widget.email);
    _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onVerifyCustom == null) {
      ref.listen<ForgotPasswordState>(forgotPasswordNotifierProvider, (_, next) {
        if (next is ForgotPasswordOtpVerified) {
          widget.onOtpVerified?.call(next.email, next.verificationToken);
          ref.read(forgotPasswordNotifierProvider.notifier).reset();
        } else if (next is ForgotPasswordOtpSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Code resent successfully!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
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
    }

    final state = ref.watch(forgotPasswordNotifierProvider);
    final isLoading = _isCustomLoading || (widget.onVerifyCustom == null && state is ForgotPasswordLoading);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                'OTP Verification',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 36),

              // ── Heading ──
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: widget.subtitle),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── OTP boxes ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_otpLength, (i) {
                  return _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (val) {
                      if (val.length == 1 && i < _otpLength - 1) {
                        _focusNodes[i + 1].requestFocus();
                      }
                      setState(() {});
                    },
                    onBackspace: () {
                      if (_controllers[i].text.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                    },
                  );
                }),
              ),

              const SizedBox(height: 20),

              // ── Resend link ──
              Center(
                child: Clickable(
                  onTap: _resendCountdown == 0 ? _onResend : null,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14),
                      children: [
                        const TextSpan(
                          text: "Didn't receive the code? ",
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        TextSpan(
                          text: _resendCountdown > 0
                              ? 'Resend (${_resendCountdown}s)'
                              : 'Resend',
                          style: TextStyle(
                            color: _resendCountdown > 0
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Verify button ──
              AuthButton(
                label: 'Verify & Proceed',
                isLoading: isLoading,
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: _onVerify,
              ),

              const SizedBox(height: 48),

              // ── Shield icon ──
              Center(
                child: ScaleTransition(
                  scale: _shieldScale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF0F7FF),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF7C3AED),
                      size: 44,
                    ),
                  ),
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

/// A single OTP digit box.
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
          }
        },
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2.5),
            ),
          ),
        ),
      ),
    );
  }
}
