import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../super_admin/presentation/screens/super_admin_shell.dart';
import 'admin_dashboard_screen.dart';
import 'student_dashboard_screen.dart';
import 'teacher_dashboard_screen.dart';

/// Async provider that loads the user's role + name from secure storage once.
/// Riverpod caches the result so it doesn't re-read storage on every rebuild.
final _userIdentityProvider = FutureProvider.autoDispose<({String role, String name})>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final role = await storage.getUserRole() ?? 'STUDENT';
  final name = await storage.getUserName() ?? 'User';
  return (role: role, name: name);
});

/// Role-router screen.
/// Reads the user role and name from [secureStorageProvider] via Riverpod
/// and routes to the appropriate role-specific dashboard.
class DashboardScreen extends ConsumerWidget {
  final VoidCallback? onLogout;
  const DashboardScreen({super.key, this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(_userIdentityProvider);

    return identity.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load user session.'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onLogout,
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
      data: (identity) {
        final userName = identity.name;
        final role = identity.role;

        if (role == 'SUPER_ADMIN') {
          return const SuperAdminShell();
        } else if (role == 'ADMIN') {
          return AdminDashboardScreen(userName: userName, onLogout: onLogout);
        } else if (role == 'TEACHER') {
          return TeacherDashboardScreen(userName: userName, onLogout: onLogout);
        } else {
          return StudentDashboardScreen(userName: userName, onLogout: onLogout);
        }
      },
    );
  }
}
