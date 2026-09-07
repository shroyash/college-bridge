import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/new_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/institution_admin/domain/entities/institution_entities.dart';
import '../../features/institution_admin/presentation/screens/institution_registration_screen.dart';
import '../../features/institution_admin/presentation/screens/registration_submitted_screen.dart';
import '../../features/super_admin/presentation/screens/super_admin_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          onComplete: () => context.go('/login'),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          onBack: () => context.go('/splash'),
          onNavigateToRegister: () => context.go('/register'),
          onForgotPassword: () => context.go('/forgot-password'),
          onLoginSuccess: () => context.go('/dashboard'),
          onLoginSuccessWithUser: (user) {
            if (user.role == 'SUPER_ADMIN') {
              context.go('/super-admin');
            } else {
              context.go('/dashboard');
            }
          },
          onNavigateToInstitutionRegister: () => context.go('/institution-register'),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(
          onBack: () => context.go('/login'),
          onNavigateToLogin: () => context.go('/login'),
          onRegisterSuccess: () => context.go('/dashboard'),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordScreen(
          onBack: () => context.go('/login'),
          onOtpSent: (email) => context.go('/otp-verification?email=$email'),
        ),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(
            email: email,
            onBack: () => context.go('/forgot-password'),
            onOtpVerified: (verifiedEmail, token) {
              context.go('/new-password?email=$verifiedEmail&token=$token');
            },
          );
        },
      ),
      GoRoute(
        path: '/new-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final token = state.uri.queryParameters['token'] ?? '';
          return NewPasswordScreen(
            email: email,
            verificationToken: token,
            onBack: () => context.go('/otp-verification'),
            onPasswordReset: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✅ Password updated successfully!'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              context.go('/login');
            },
          );
        },
      ),
      GoRoute(
        path: '/institution-register',
        builder: (context, state) => InstitutionRegistrationScreen(
          onBack: () => context.go('/login'),
          onSuccess: (result) {
            context.go('/registration-submitted', extra: result);
          },
        ),
      ),
      GoRoute(
        path: '/registration-submitted',
        builder: (context, state) {
          final result = state.extra as InstitutionRegistrationResult?;
          if (result == null) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Back to Login'),
                ),
              ),
            );
          }
          return RegistrationSubmittedScreen(
            result: result,
            onGoToLogin: () => context.go('/login'),
          );
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => DashboardScreen(
          onLogout: () => context.go('/login'),
        ),
      ),
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminShell(),
      ),
    ],
  );
});
