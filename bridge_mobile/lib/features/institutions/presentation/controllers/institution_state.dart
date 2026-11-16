import 'package:equatable/equatable.dart';

import '../../domain/entities/institution_entities.dart';

// ── Institution Registration State ────────────────────────────────────────────

sealed class InstitutionRegistrationState extends Equatable {
  const InstitutionRegistrationState();
  @override
  List<Object?> get props => [];
}

final class RegistrationInitial extends InstitutionRegistrationState {
  const RegistrationInitial();
}

final class RegistrationLoading extends InstitutionRegistrationState {
  const RegistrationLoading();
}

final class RegistrationSuccess extends InstitutionRegistrationState {
  final InstitutionRegistrationResult result;
  const RegistrationSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

final class RegistrationFailure extends InstitutionRegistrationState {
  final String message;
  const RegistrationFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Pending Institutions State ─────────────────────────────────────────────────

sealed class PendingInstitutionsState extends Equatable {
  const PendingInstitutionsState();
  @override
  List<Object?> get props => [];
}

final class PendingInstitutionsInitial extends PendingInstitutionsState {
  const PendingInstitutionsInitial();
}

final class PendingInstitutionsLoading extends PendingInstitutionsState {
  const PendingInstitutionsLoading();
}

final class PendingInstitutionsLoaded extends PendingInstitutionsState {
  final List<PendingInstitution> institutions;
  const PendingInstitutionsLoaded(this.institutions);
  @override
  List<Object?> get props => [institutions];
}

final class PendingInstitutionsError extends PendingInstitutionsState {
  final String message;
  const PendingInstitutionsError(this.message);
  @override
  List<Object?> get props => [message];
}

// Used while approving/rejecting a single institution
final class InstitutionActionLoading extends PendingInstitutionsState {
  final int institutionId;
  const InstitutionActionLoading(this.institutionId);
  @override
  List<Object?> get props => [institutionId];
}

// ── Managed Institutions State ────────────────────────────────────────────────

sealed class ManagedInstitutionsState extends Equatable {
  const ManagedInstitutionsState();
  @override
  List<Object?> get props => [];
}

final class ManagedInstitutionsInitial extends ManagedInstitutionsState {
  const ManagedInstitutionsInitial();
}

final class ManagedInstitutionsLoading extends ManagedInstitutionsState {
  const ManagedInstitutionsLoading();
}

final class ManagedInstitutionsLoaded extends ManagedInstitutionsState {
  final List<ManagedInstitution> institutions;
  const ManagedInstitutionsLoaded(this.institutions);
  @override
  List<Object?> get props => [institutions];
}

final class ManagedInstitutionsError extends ManagedInstitutionsState {
  final String message;
  const ManagedInstitutionsError(this.message);
  @override
  List<Object?> get props => [message];
}

final class ManagedInstitutionActionLoading extends ManagedInstitutionsState {
  final int institutionId;
  const ManagedInstitutionActionLoading(this.institutionId);
  @override
  List<Object?> get props => [institutionId];
}
