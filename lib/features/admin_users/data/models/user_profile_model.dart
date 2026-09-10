import '../../domain/entities/user_profile.dart';

class StudentProfileDetailsModel extends StudentProfileDetails {
  const StudentProfileDetailsModel({
    super.faculty,
    super.semester,
    super.academicClassId,
  });

  factory StudentProfileDetailsModel.fromJson(Map<String, dynamic> json) {
    final rawFaculty = json['faculty'] as String? ??
        json['programName'] as String? ??
        json['programCode'] as String?;
    final rawSemester = json['semester']?.toString() ??
        json['levelNumber']?.toString() ??
        json['levelName']?.toString();

    return StudentProfileDetailsModel(
      faculty: rawFaculty,
      semester: rawSemester,
      academicClassId: (json['academicClassId'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'faculty': faculty,
        'semester': semester,
        'academicClassId': academicClassId,
      };
}

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.userId,
    super.teacherId,
    required super.name,
    required super.email,
    required super.role,
    required super.status,
    super.imageUrl,
    super.fcmToken,
    super.studentDetails,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: (json['userId'] as num).toInt(),
      teacherId: (json['teacherId'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      imageUrl: json['imageUrl'] as String?,
      fcmToken: json['fcmToken'] as String?,
      studentDetails: json['studentDetails'] != null
          ? StudentProfileDetailsModel.fromJson(
              json['studentDetails'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'teacherId': teacherId,
        'name': name,
        'email': email,
        'role': role,
        'status': status,
        'imageUrl': imageUrl,
        'fcmToken': fcmToken,
      };
}