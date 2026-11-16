class SupportTicketModel {
  final int ticketId;
  final String ticketNumber;
  final int userId;
  final String userName;
  final String userEmail;
  final String userRole;
  final int? institutionId;
  final String category;
  final String subject;
  final String description;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupportTicketModel({
    required this.ticketId,
    required this.ticketNumber,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    this.institutionId,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      ticketId: (json['ticketId'] as num?)?.toInt() ?? 0,
      ticketNumber: json['ticketNumber'] as String? ?? '',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      userName: json['userName'] as String? ?? 'User',
      userEmail: json['userEmail'] as String? ?? '',
      userRole: json['userRole'] as String? ?? 'STUDENT',
      institutionId: (json['institutionId'] as num?)?.toInt(),
      category: json['category'] as String? ?? 'General Inquiry',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'ticketNumber': ticketNumber,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userRole': userRole,
      'institutionId': institutionId,
      'category': category,
      'subject': subject,
      'description': description,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

