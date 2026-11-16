import 'package:equatable/equatable.dart';

class AcademicClass extends Equatable {
  final int classId;
  final String faculty;
  final int semester;
  final String displayName;
  final int totalStudents;
  final int? classTeacherId;
  final String? classTeacherName;

  const AcademicClass({
    required this.classId,
    required this.faculty,
    required this.semester,
    required this.displayName,
    this.totalStudents = 0,
    this.classTeacherId,
    this.classTeacherName,
  });

  @override
  List<Object?> get props => [
        classId,
        faculty,
        semester,
        displayName,
        totalStudents,
        classTeacherId,
        classTeacherName,
      ];
}
