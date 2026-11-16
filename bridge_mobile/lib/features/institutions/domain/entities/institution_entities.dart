import 'package:equatable/equatable.dart';

/// Domain entity for a document attached to a pending institution.
class InstitutionDocument extends Equatable {
  final int documentId;
  final String documentUrl;
  final String documentType;
  final String? uploadedAt;

  const InstitutionDocument({
    required this.documentId,
    required this.documentUrl,
    required this.documentType,
    this.uploadedAt,
  });

  @override
  List<Object?> get props => [documentId, documentUrl, documentType, uploadedAt];
}

/// Domain entity for a pending institution awaiting super-admin review.
class PendingInstitution extends Equatable {
  final int institutionId;
  final String name;
  final String code;
  final String status;
  final String? submittedAt;
  final String? adminName;
  final String? adminEmail;
  final String? rejectionReason;
  final String? reviewedAt;
  final List<InstitutionDocument> documents;

  const PendingInstitution({
    required this.institutionId,
    required this.name,
    required this.code,
    required this.status,
    this.submittedAt,
    this.adminName,
    this.adminEmail,
    this.rejectionReason,
    this.reviewedAt,
    this.documents = const [],
  });

  int get documentCount => documents.length;

  @override
  List<Object?> get props => [
        institutionId, name, code, status, submittedAt,
        adminName, adminEmail, documents,
      ];
}

/// Domain entity for an active/suspended institution in the management list.
class ManagedInstitution extends Equatable {
  final int institutionId;
  final String name;
  final String code;
  final String status; // ACTIVE | SUSPENDED
  final String? createdAt;

  const ManagedInstitution({
    required this.institutionId,
    required this.name,
    required this.code,
    required this.status,
    this.createdAt,
  });

  bool get isActive => status == 'ACTIVE';

  @override
  List<Object?> get props => [institutionId, name, code, status];
}

/// Holds the result of a successful institution registration (no JWT issued).
class InstitutionRegistrationResult extends Equatable {
  final int institutionId;
  final String name;
  final String code;
  final String status;
  final String message;
  final String? submittedAt;

  const InstitutionRegistrationResult({
    required this.institutionId,
    required this.name,
    required this.code,
    required this.status,
    required this.message,
    this.submittedAt,
  });

  @override
  List<Object?> get props => [institutionId, name, code, status, message];
}
