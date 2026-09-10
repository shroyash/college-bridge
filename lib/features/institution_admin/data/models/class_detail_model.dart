class ClassStudentModel {
  final int studentId;
  final int? userId;
  final String fullName;
  final String email;
  final String status;

  const ClassStudentModel({
    required this.studentId,
    this.userId,
    required this.fullName,
    required this.email,
    required this.status,
  });

  factory ClassStudentModel.fromJson(Map<String, dynamic> json) {
    return ClassStudentModel(
      studentId: (json['studentId'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt(),
      fullName: json['fullName'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

class ClassTeacherModel {
  final int teacherId;
  final int? userId;
  final String fullName;
  final String email;
  final List<String> assignedSubjects;
  final bool isClassTeacher;

  const ClassTeacherModel({
    required this.teacherId,
    this.userId,
    required this.fullName,
    required this.email,
    required this.assignedSubjects,
    required this.isClassTeacher,
  });

  factory ClassTeacherModel.fromJson(Map<String, dynamic> json) {
    final subList = (json['assignedSubjects'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return ClassTeacherModel(
      teacherId: (json['teacherId'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt(),
      fullName: json['fullName'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      assignedSubjects: subList,
      isClassTeacher: json['isClassTeacher'] as bool? ?? false,
    );
  }
}

class ClassDetailModel {
  final int levelId;
  final String displayName;
  final String levelName;
  final String programName;
  final int totalStudents;
  final int? classTeacherId;
  final String? classTeacherName;
  final int institutionId;
  final String institutionName;
  final String createdBy;
  final String createdAt;
  final String status;
  final List<ClassStudentModel> students;
  final List<ClassTeacherModel> teachers;

  // Backwards compatibility getters
  int get classId => levelId;
  String get faculty => programName;
  int get semester => 1;

  const ClassDetailModel({
    required this.levelId,
    required this.displayName,
    required this.levelName,
    required this.programName,
    required this.totalStudents,
    this.classTeacherId,
    this.classTeacherName,
    required this.institutionId,
    required this.institutionName,
    required this.createdBy,
    required this.createdAt,
    this.status = 'ACTIVE',
    required this.students,
    required this.teachers,
  });

  factory ClassDetailModel.fromJson(Map<String, dynamic> json) {
    final studentsJson = (json['students'] as List?)
            ?.whereType<Map>()
            .map((e) => ClassStudentModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    final teachersJson = (json['teachers'] as List?)
            ?.whereType<Map>()
            .map((e) => ClassTeacherModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    final lId = (json['levelId'] ?? json['subjectId'] ?? json['classId'] as num?)?.toInt() ?? 0;
    final progName = json['programName'] ??
        (json['academicProgram'] is Map ? json['academicProgram']['name'] : null) ??
        json['faculty'] as String? ??
        '';
    final lvlName = json['levelName'] ??
        (json['academicLevel'] is Map ? json['academicLevel']['name'] : null) ??
        json['subjectName'] ??
        json['displayName'] as String? ??
        '';

    final teacherInfo = json['teacher'] is Map ? json['teacher'] as Map : null;
    final tId = (json['classTeacherId'] ?? teacherInfo?['teacherId'] as num?)?.toInt();
    final tName = json['classTeacherName'] ?? teacherInfo?['name'] as String?;
    final totalSt = (json['totalStudents'] ?? json['studentCount'] as num?)?.toInt() ?? 0;
    final st = json['status'] as String? ?? 'ACTIVE';

    return ClassDetailModel(
      levelId: lId,
      displayName: json['displayName'] as String? ?? (json['subjectName'] != null ? '${json['subjectName']} ($lvlName)' : lvlName),
      levelName: lvlName,
      programName: progName,
      totalStudents: totalSt,
      classTeacherId: tId,
      classTeacherName: tName,
      institutionId: (json['institutionId'] as num?)?.toInt() ?? 0,
      institutionName: json['institutionName'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? 'Institution Admin',
      createdAt: json['createdAt'] as String? ?? '',
      status: st,
      students: studentsJson,
      teachers: teachersJson,
    );
  }
}
