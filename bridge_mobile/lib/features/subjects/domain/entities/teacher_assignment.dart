class TeacherAssignment {
  final int assignmentId;
  final int subjectId;
  final String subjectName;
  final String? faculty;
  final int? semester;

  const TeacherAssignment({
    required this.assignmentId,
    required this.subjectId,
    required this.subjectName,
    this.faculty,
    this.semester,
  });
}
