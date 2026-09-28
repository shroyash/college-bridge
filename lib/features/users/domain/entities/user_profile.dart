class StudentProfileDetails {
  final String? faculty;
  final String? semester;
  final int? academicClassId;

  const StudentProfileDetails({
    this.faculty,
    this.semester,
    this.academicClassId,
  });
}

class UserProfile {
  final int userId;
  final int? teacherId;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? imageUrl;
  final String? fcmToken;
  final StudentProfileDetails? studentDetails;

  const UserProfile({
    required this.userId,
    this.teacherId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.imageUrl,
    this.fcmToken,
    this.studentDetails,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isSuspended => status.toUpperCase() == 'SUSPENDED';
  bool get isTeacher => teacherId != null;
}