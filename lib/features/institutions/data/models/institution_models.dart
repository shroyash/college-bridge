import '../../domain/entities/institution_entities.dart';

class InstitutionDocumentModel extends InstitutionDocument {
  const InstitutionDocumentModel({
    required super.documentId,
    required super.documentUrl,
    required super.documentType,
    super.uploadedAt,
  });

  factory InstitutionDocumentModel.fromJson(Map<String, dynamic> json) {
    return InstitutionDocumentModel(
      documentId: json['documentId'] as int? ?? 0,
      documentUrl: json['documentUrl'] as String? ?? '',
      documentType: json['documentType'] as String? ?? 'DOCUMENT',
      uploadedAt: json['uploadedAt'] as String?,
    );
  }
}

class PendingInstitutionModel extends PendingInstitution {
  const PendingInstitutionModel({
    required super.institutionId,
    required super.name,
    required super.code,
    required super.status,
    super.submittedAt,
    super.adminName,
    super.adminEmail,
    super.rejectionReason,
    super.reviewedAt,
    super.documents,
  });

  factory PendingInstitutionModel.fromJson(Map<String, dynamic> json) {
    final rawDocs = json['documents'] as List<dynamic>? ?? [];
    final docs = rawDocs
        .map((d) => InstitutionDocumentModel.fromJson(d as Map<String, dynamic>))
        .toList();

    return PendingInstitutionModel(
      institutionId: json['institutionId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      submittedAt: json['submittedAt'] as String?,
      adminName: json['adminName'] as String?,
      adminEmail: json['adminEmail'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
      documents: docs,
    );
  }
}

class ManagedInstitutionModel extends ManagedInstitution {
  const ManagedInstitutionModel({
    required super.institutionId,
    required super.name,
    required super.code,
    required super.status,
    super.createdAt,
  });

  factory ManagedInstitutionModel.fromJson(Map<String, dynamic> json) {
    return ManagedInstitutionModel(
      institutionId: json['institutionId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['createdAt'] as String?,
    );
  }
}

class InstitutionRegistrationResultModel extends InstitutionRegistrationResult {
  const InstitutionRegistrationResultModel({
    required super.institutionId,
    required super.name,
    required super.code,
    required super.status,
    required super.message,
    super.submittedAt,
  });

  factory InstitutionRegistrationResultModel.fromJson(
      Map<String, dynamic> json) {
    return InstitutionRegistrationResultModel(
      institutionId: json['institutionId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      message: json['message'] as String? ?? 'Registration submitted.',
      submittedAt: json['submittedAt'] as String?,
    );
  }
}
