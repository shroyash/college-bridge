import '../../domain/entities/teacher_assignment.dart';

class TeacherAssignmentModel extends TeacherAssignment {
  const TeacherAssignmentModel({
    required super.assignmentId,
    required super.subjectId,
    required super.subjectName,
    super.faculty,
    super.semester,
  });

  factory TeacherAssignmentModel.fromJson(Map<String, dynamic> json) {
    return TeacherAssignmentModel(
      assignmentId: (json['assignmentId'] as num).toInt(),
      subjectId: (json['subjectId'] as num).toInt(),
      subjectName: json['subjectName'] as String? ?? '',
      faculty: json['faculty'] as String?,
      semester: json['semester'] != null ? (json['semester'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'assignmentId': assignmentId,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'faculty': faculty,
        'semester': semester,
      };
}
