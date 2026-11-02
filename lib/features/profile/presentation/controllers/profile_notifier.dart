import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin_users/domain/entities/user_profile.dart';
import '../../../admin_users/domain/usecases/manage_teacher_assignments_usecase.dart';
import '../../../../core/storage/secure_storage_service.dart';

// ── State ──────────────────────────────────────────────────────────────────────

abstract class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileSuccess extends ProfileState {
  final UserProfile profile;
  final bool isSaving;

  const ProfileSuccess(this.profile, {this.isSaving = false});

  ProfileSuccess copyWith({UserProfile? profile, bool? isSaving}) {
    return ProfileSuccess(
      profile ?? this.profile,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class ProfileFailure extends ProfileState {
  final String message;
  const ProfileFailure(this.message);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ManageTeacherAssignmentsUseCase _useCase;
  final SecureStorageService _storage;

  ProfileNotifier(this._useCase, this._storage) : super(const ProfileInitial());

  Future<void> fetchProfile() async {
    // Skip re-fetching if we already have fresh data (avoids unnecessary loading
    // flicker when navigating back to the profile screen).
    if (state is ProfileSuccess) return;
    await _loadProfile();
  }

  /// Forces a fresh fetch regardless of current state (e.g. after image upload or retry).
  Future<void> refreshProfile() => _loadProfile();

  Future<UserProfile?> _getCachedProfile() async {
    final name = await _storage.getUserName();
    final email = await _storage.getUserEmail();
    final role = await _storage.getUserRole();
    if ((name != null && name.isNotEmpty) || (email != null && email.isNotEmpty)) {
      return UserProfile(
        userId: 0,
        name: name ?? '',
        email: email ?? '',
        role: role ?? 'ADMIN',
        status: 'ACTIVE',
      );
    }
    return null;
  }

  Future<void> _loadProfile() async {
    UserProfile? fallback;
    if (state is ProfileSuccess) {
      fallback = (state as ProfileSuccess).profile;
    } else {
      fallback = await _getCachedProfile();
      if (fallback != null) {
        state = ProfileSuccess(fallback);
      } else {
        state = const ProfileLoading();
      }
    }

    try {
      final profile = await _useCase.getMyProfile().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timed out. Please try again.'),
      );
      state = ProfileSuccess(profile);
    } catch (e) {
      if (fallback != null) {
        state = ProfileSuccess(fallback);
      } else {
        state = ProfileFailure(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  /// Calls PUT /api/account/profile and refreshes state with the returned profile.
  Future<bool> updateName(String newName) async {
    if (state is! ProfileSuccess) return false;
    final current = (state as ProfileSuccess).profile;
    state = ProfileSuccess(current, isSaving: true);
    try {
      final updated = await _useCase.updateProfile(name: newName);
      state = ProfileSuccess(updated);
      return true;
    } catch (_) {
      state = ProfileSuccess(current, isSaving: false);
      return false;
    }
  }

  /// Calls POST /api/account/profile/image and refreshes state with the updated imageUrl.
  Future<bool> uploadProfileImage(File imageFile) async {
    if (state is! ProfileSuccess) return false;
    final current = (state as ProfileSuccess).profile;
    state = ProfileSuccess(current, isSaving: true);
    try {
      await _useCase.uploadProfileImage(imageFile);
      // Re-fetch profile to get the updated imageUrl from server
      await _loadProfile();
      return true;
    } catch (_) {
      state = ProfileSuccess(current, isSaving: false);
      return false;
    }
  }

  /// Calls POST /api/auth/logout to revoke refresh token, then clears local storage.
  Future<void> logoutAndClear() async {
    try {
      await _useCase.logout();
    } catch (_) {
      // Even if the API call fails, proceed with local clear
    }
    await _storage.clearAll();
  }
}
