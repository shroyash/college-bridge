import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bridge_mobile/features/profile/presentation/screens/admin_profile_screen.dart';
import 'package:bridge_mobile/features/profile/presentation/controllers/profile_notifier.dart';
import 'package:bridge_mobile/features/dashboard/presentation/controllers/dashboard_providers.dart';
import 'package:bridge_mobile/features/admin_users/domain/entities/user_profile.dart';

class MockProfileNotifier extends StateNotifier<ProfileState>
    implements ProfileNotifier {
  MockProfileNotifier(super.state);

  @override
  Future<void> fetchProfile() async {}

  @override
  Future<void> refreshProfile() async {}

  @override
  Future<bool> updateName(String newName) async => true;

  @override
  Future<bool> uploadProfileImage(dynamic imageFile) async => true;

  @override
  Future<void> logoutAndClear() async {}
}

void main() {
  testWidgets('AdminProfileScreen displays profile content on ProfileSuccess',
      (tester) async {
    const mockProfile = UserProfile(
      userId: 1,
      name: 'College Admin',
      email: 'admin@college.edu',
      role: 'ADMIN',
      status: 'ACTIVE',
    );

    final mockNotifier = MockProfileNotifier(
      const ProfileSuccess(mockProfile),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith((ref) => mockNotifier),
        ],
        child: const MaterialApp(
          home: AdminProfileScreen(userName: 'College Admin'),
        ),
      ),
    );

    await tester.pump();

    // Verify it is NOT stuck in CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Verify profile information is rendered
    expect(find.text('College Admin'), findsOneWidget);
    expect(find.text('admin@college.edu'), findsWidgets);
    expect(find.text('ADMIN'), findsOneWidget);
  });

  testWidgets('AdminProfileScreen displays error view on ProfileFailure',
      (tester) async {
    final mockNotifier = MockProfileNotifier(
      const ProfileFailure('Failed to load profile'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith((ref) => mockNotifier),
        ],
        child: const MaterialApp(
          home: AdminProfileScreen(userName: 'College Admin'),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Failed to load profile'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

