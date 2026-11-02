import '../../domain/entities/academic_class.dart';

class AcademicClassModel extends AcademicClass {
  const AcademicClassModel({
    required super.classId,
    required super.faculty,
    required super.semester,
    required super.displayName,
    super.totalStudents = 0,
    super.classTeacherId,
    super.classTeacherName,
  });

  factory AcademicClassModel.fromJson(Map<String, dynamic> json) {
    final facultyStr = (json['programName'] as String?) ??
        (json['faculty'] as String?) ??
        '';

    final levelNameStr = (json['levelName'] as String?) ?? '';
    int semInt = (json['semester'] as num?)?.toInt() ?? 1;
    if (levelNameStr.isNotEmpty) {
      final match = RegExp(r'\d+').firstMatch(levelNameStr);
      if (match != null) {
        semInt = int.tryParse(match.group(0)!) ?? semInt;
      }
    }

    final subjectName = json['name'] as String?;
    final defaultDisplayName = subjectName != null && subjectName.isNotEmpty
        ? subjectName
        : (facultyStr.isNotEmpty ? '$facultyStr Sem $semInt' : 'Class Sem $semInt');

    // Prefer subjectId (for teacher assigned subjects) then classId, falling back to levelId
    final resolvedClassId = (json['subjectId'] as num?)?.toInt() ??
        (json['classId'] as num?)?.toInt() ??
        (json['levelId'] as num?)?.toInt() ??
        0;

    return AcademicClassModel(
      classId: resolvedClassId,
      faculty: facultyStr,
      semester: semInt,
      displayName: json['displayName'] as String? ?? defaultDisplayName,
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      classTeacherId: (json['classTeacherId'] as num?)?.toInt(),
      classTeacherName: json['classTeacherName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'faculty': faculty,
      'semester': semester,
      'displayName': displayName,
      'totalStudents': totalStudents,
      'classTeacherId': classTeacherId,
      'classTeacherName': classTeacherName,
    };
  }
}
