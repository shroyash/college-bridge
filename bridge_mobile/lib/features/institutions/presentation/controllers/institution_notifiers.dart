import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/institution_admin_repository.dart';
import '../../domain/entities/institution_entities.dart';
import 'institution_state.dart';

// ── Institution Registration Notifier ─────────────────────────────────────────

class InstitutionRegistrationNotifier
    extends StateNotifier<InstitutionRegistrationState> {
  final InstitutionAdminRepository _repository;

  InstitutionRegistrationNotifier(this._repository)
      : super(const RegistrationInitial());

  Future<void> register({
    required String institutionName,
    required String institutionCode,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required List<MapEntry<String, MultipartFile>> documents,
  }) async {
    state = const RegistrationLoading();
    try {
      final result = await _repository.registerInstitution(
        institutionName: institutionName,
        institutionCode: institutionCode,
        adminName: adminName,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
        documents: documents,
      );
      state = RegistrationSuccess(result);
    } catch (e) {
      state = RegistrationFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void reset() => state = const RegistrationInitial();
}

// ── Pending Institutions Notifier ─────────────────────────────────────────────

class PendingInstitutionsNotifier
    extends StateNotifier<PendingInstitutionsState> {
  final InstitutionAdminRepository _repository;

  PendingInstitutionsNotifier(this._repository)
      : super(const PendingInstitutionsInitial());

  Future<void> loadPending() async {
    state = const PendingInstitutionsLoading();
    try {
      final list = await _repository.getPendingInstitutions();
      state = PendingInstitutionsLoaded(list);
    } catch (e) {
      state = PendingInstitutionsError(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> approve(int institutionId) async {
    final prevState = state;
    state = InstitutionActionLoading(institutionId);
    try {
      await _repository.approveInstitution(institutionId);
      // Remove from list
      if (prevState is PendingInstitutionsLoaded) {
        final updated = prevState.institutions
            .where((i) => i.institutionId != institutionId)
            .toList();
        state = PendingInstitutionsLoaded(updated);
      } else {
        await loadPending();
      }
    } catch (e) {
      state = PendingInstitutionsError(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> reject(int institutionId, String reason) async {
    final prevState = state;
    state = InstitutionActionLoading(institutionId);
    try {
      await _repository.rejectInstitution(institutionId, reason);
      if (prevState is PendingInstitutionsLoaded) {
        final updated = prevState.institutions
            .where((i) => i.institutionId != institutionId)
            .toList();
        state = PendingInstitutionsLoaded(updated);
      } else {
        await loadPending();
      }
    } catch (e) {
      state = PendingInstitutionsError(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

// ── Managed Institutions Notifier ─────────────────────────────────────────────

class ManagedInstitutionsNotifier
    extends StateNotifier<ManagedInstitutionsState> {
  final InstitutionAdminRepository _repository;

  ManagedInstitutionsNotifier(this._repository)
      : super(const ManagedInstitutionsInitial());

  Future<void> load() async {
    state = const ManagedInstitutionsLoading();
    try {
      final list = await _repository.getManagedInstitutions();
      state = ManagedInstitutionsLoaded(list);
    } catch (e) {
      state = ManagedInstitutionsError(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> suspend(int institutionId) async {
    final prevState = state;
    state = ManagedInstitutionActionLoading(institutionId);
    try {
      await _repository.suspendInstitution(institutionId);
      // Update status in list
      if (prevState is ManagedInstitutionsLoaded) {
        final updated = prevState.institutions.map((i) {
          if (i.institutionId == institutionId) {
            return ManagedInstitution(
              institutionId: i.institutionId,
              name: i.name,
              code: i.code,
              status: 'SUSPENDED',
              createdAt: i.createdAt,
            );
          }
          return i;
        }).toList();
        state = ManagedInstitutionsLoaded(updated);
      } else {
        await load();
      }
    } catch (e) {
      state = ManagedInstitutionsError(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> reactivate(int institutionId) async {
    final prevState = state;
    state = ManagedInstitutionActionLoading(institutionId);
    try {
      await _repository.reactivateInstitution(institutionId);
      if (prevState is ManagedInstitutionsLoaded) {
        final updated = prevState.institutions.map((i) {
          if (i.institutionId == institutionId) {
            return ManagedInstitution(
              institutionId: i.institutionId,
              name: i.name,
              code: i.code,
              status: 'ACTIVE',
              createdAt: i.createdAt,
            );
          }
          return i;
        }).toList();
        state = ManagedInstitutionsLoaded(updated);
      } else {
        await load();
      }
    } catch (e) {
      state = ManagedInstitutionsError(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
