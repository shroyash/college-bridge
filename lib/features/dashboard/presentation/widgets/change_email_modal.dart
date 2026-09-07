import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/screens/otp_verification_screen.dart';
import '../controllers/dashboard_providers.dart';

class ChangeEmailModal extends ConsumerStatefulWidget {
  final String currentEmail;

  const ChangeEmailModal({super.key, required this.currentEmail});

  static Future<void> show(BuildContext context, String currentEmail) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeEmailModal(currentEmail: currentEmail),
    );
  }

  @override
  ConsumerState<ChangeEmailModal> createState() => _ChangeEmailModalState();
}

class _ChangeEmailModalState extends ConsumerState<ChangeEmailModal> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleInitiateEmailChange() async {
    final newEmail = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (newEmail.isEmpty || !newEmail.contains('@')) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    if (password.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter your current password')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/api/account/email/initiate',
        data: {
          'newEmail': newEmail,
          'currentPassword': password,
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Close modal sheet

      // Navigate to reusable OtpVerificationScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (routeCtx) => OtpVerificationScreen(
            email: newEmail,
            title: 'Verify New Email',
            subtitle: 'We sent a 6-digit confirmation code to\n',
            onBack: () => Navigator.pop(routeCtx),
            onVerifyCustom: (activeRef, otp) async {
              final api = activeRef.read(apiClientProvider);
              final profileNotifier = activeRef.read(profileNotifierProvider.notifier);

              await api.post(
                '/api/account/email/confirm',
                data: {
                  'newEmail': newEmail,
                  'code': otp,
                },
              );

              profileNotifier.fetchProfile();

              if (routeCtx.mounted) {
                Navigator.pop(routeCtx);
                ScaffoldMessenger.of(routeCtx).showSnackBar(
                  const SnackBar(
                    content: Text('Email updated successfully! Please log in again with your new email.'),
                    backgroundColor: Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            onResendCustom: (activeRef) async {
              final api = activeRef.read(apiClientProvider);
              await api.post(
                '/api/account/email/initiate',
                data: {
                  'newEmail': newEmail,
                  'currentPassword': password,
                },
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final msg = e.toString().replaceAll('Exception: ', '');
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to initiate email change: $msg'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Change Email Address',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Current: ${widget.currentEmail}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'New Email Address',
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2563EB)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: _hidePassword,
            decoration: InputDecoration(
              labelText: 'Current Password',
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2563EB)),
              suffixIcon: IconButton(
                icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleInitiateEmailChange,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Send Verification OTP',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
