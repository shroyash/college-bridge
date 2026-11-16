class PaginatedResponse<T> {
  final List<T> content;
  final int currentPage;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginatedResponse({
    required this.content,
    required this.currentPage,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    final list = json['content'] as List? ?? [];
    return PaginatedResponse<T>(
      content:
          list.map((item) => fromJsonT(item as Map<String, dynamic>)).toList(),
      currentPage: json['currentPage'] ?? json['number'] ?? 0,
      pageSize: json['pageSize'] ?? json['size'] ?? 20,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNext: json['hasNext'] ?? !(json['last'] ?? true),
      hasPrevious: json['hasPrevious'] ?? !(json['first'] ?? true),
    );
  }
}

class SuperAdminDashboardStats {
  final int totalInstitutions;
  final int pendingInstitutions;
  final int activeInstitutions;
  final int suspendedInstitutions;
  final int totalUsers;
  final int totalStudents;
  final int totalTeachers;
  final int totalAdmins;

  SuperAdminDashboardStats({
    required this.totalInstitutions,
    required this.pendingInstitutions,
    required this.activeInstitutions,
    required this.suspendedInstitutions,
    required this.totalUsers,
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalAdmins,
  });

  factory SuperAdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final inst = json['institutions'] as Map<String, dynamic>? ?? {};
    final users = json['users'] as Map<String, dynamic>? ?? {};

    return SuperAdminDashboardStats(
      totalInstitutions: (inst['total'] as num?)?.toInt() ?? 0,
      pendingInstitutions: (inst['pending'] as num?)?.toInt() ?? 0,
      activeInstitutions: (inst['active'] as num?)?.toInt() ?? 0,
      suspendedInstitutions: (inst['suspended'] as num?)?.toInt() ?? 0,
      totalUsers: (users['total'] as num?)?.toInt() ?? 0,
      totalStudents: (users['students'] as num?)?.toInt() ?? 0,
      totalTeachers: (users['teachers'] as num?)?.toInt() ?? 0,
      totalAdmins: (users['admins'] as num?)?.toInt() ?? 0,
    );
  }
}

class SuperAdminUser {
  final int id;
  final String name;
  final String email;
  final String? profileImage;
  final String role;
  final String status;
  final int? institutionId;
  final String? institutionName;
  final String? createdAt;
  final String? phone;
  final String? faculty;
  final String? semester;
  final String? codeId;
  final String? verificationStatus;
  final String? lastActivity;

  SuperAdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.role,
    required this.status,
    this.institutionId,
    this.institutionName,
    this.createdAt,
    this.phone,
    this.faculty,
    this.semester,
    this.codeId,
    this.verificationStatus,
    this.lastActivity,
  });

  factory SuperAdminUser.fromJson(Map<String, dynamic> json) {
    return SuperAdminUser(
      id: json['id'] ?? json['userId'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'] ?? json['imageUrl'],
      role: json['role'] ?? 'STUDENT',
      status: json['status'] ?? 'ACTIVE',
      institutionId: json['institutionId'],
      institutionName: json['institutionName'],
      createdAt: json['createdAt'],
      phone: json['phone'] ?? json['contactNumber'],
      faculty: json['faculty'] ?? json['department'],
      semester: json['semester']?.toString(),
      codeId: json['studentId'] ?? json['teacherId'] ?? json['userCode'],
      verificationStatus: json['verificationStatus'] ?? json['verificationState'],
      lastActivity: json['lastActivity'] ?? json['updatedAt'],
    );
  }
}

class SuperAdminInstitution {
  final int institutionId;
  final String institutionName;
  final String? code;
  final String? profileImage;
  final String location;
  final String? website;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final String status;
  final int totalStudents;
  final int totalTeachers;
  final int totalAdmins;
  final int activeUsers;
  final int suspendedUsers;
  final String? createdAt;

  SuperAdminInstitution({
    required this.institutionId,
    required this.institutionName,
    this.code,
    this.profileImage,
    required this.location,
    this.website,
    this.contactEmail,
    this.contactPhone,
    this.address,
    required this.status,
    required this.totalStudents,
    required this.totalTeachers,
    this.totalAdmins = 0,
    this.activeUsers = 0,
    this.suspendedUsers = 0,
    this.createdAt,
  });

  factory SuperAdminInstitution.fromJson(Map<String, dynamic> json) {
    return SuperAdminInstitution(
      institutionId: json['institutionId'] ?? 0,
      institutionName: json['institutionName'] ?? json['name'] ?? '',
      code: json['code'],
      profileImage: json['profileImage'],
      location: json['location'] ?? 'Kathmandu',
      website: json['website'],
      contactEmail: json['contactEmail'] ?? json['email'],
      contactPhone: json['contactPhone'] ?? json['phone'],
      address: json['address'] ?? json['location'],
      status: json['status'] ?? 'ACTIVE',
      totalStudents: json['totalStudents'] ?? 0,
      totalTeachers: json['totalTeachers'] ?? 0,
      totalAdmins: json['totalAdmins'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      suspendedUsers: json['suspendedUsers'] ?? 0,
      createdAt: json['createdAt'],
    );
  }
}

class PendingDocument {
  final int documentId;
  final String documentUrl;
  final String documentType;
  final String? uploadedAt;

  PendingDocument({
    required this.documentId,
    required this.documentUrl,
    required this.documentType,
    this.uploadedAt,
  });

  factory PendingDocument.fromJson(Map<String, dynamic> json) {
    return PendingDocument(
      documentId: json['documentId'] ?? 0,
      documentUrl: json['documentUrl'] ?? '',
      documentType: json['documentType'] ?? 'DOCUMENT',
      uploadedAt: json['uploadedAt'],
    );
  }
}

class SuperAdminPendingInstitution {
  final int institutionId;
  final String institutionName;
  final String? code;
  final String? profileImage;
  final String location;
  final String? website;
  final String? contactPerson;
  final String? email;
  final String status;
  final int totalStudents;
  final int totalTeachers;
  final String? submittedAt;
  final List<PendingDocument> documents;

  SuperAdminPendingInstitution({
    required this.institutionId,
    required this.institutionName,
    this.code,
    this.profileImage,
    required this.location,
    this.website,
    this.contactPerson,
    this.email,
    required this.status,
    required this.totalStudents,
    required this.totalTeachers,
    this.submittedAt,
    this.documents = const [],
  });

  factory SuperAdminPendingInstitution.fromJson(Map<String, dynamic> json) {
    final rawDocs = json['documents'] as List? ?? [];
    return SuperAdminPendingInstitution(
      institutionId: json['institutionId'] ?? 0,
      institutionName: json['institutionName'] ?? json['name'] ?? '',
      code: json['code'],
      profileImage: json['profileImage'],
      location: json['location'] ?? 'Kathmandu',
      website: json['website'],
      contactPerson: json['contactPerson'] ?? json['submittedByAdminName'],
      email: json['email'] ?? json['submittedByAdminEmail'],
      status: json['status'] ?? 'PENDING',
      totalStudents: json['totalStudents'] ?? 0,
      totalTeachers: json['totalTeachers'] ?? 0,
      submittedAt: json['submittedAt'] ?? json['createdAt'],
      documents: rawDocs.map((d) => PendingDocument.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}
