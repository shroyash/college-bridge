import 'package:equatable/equatable.dart';

/// Domain entity for an Academic Level (e.g., Semester 1, Year 2).
class AcademicLevel extends Equatable {
  final int levelId;
  final int levelNumber;
  final String name;
  final String type; // SEMESTER, YEAR, GRADE
  final int programId;
  final String programName;
  final String programCode;

  const AcademicLevel({
    required this.levelId,
    required this.levelNumber,
    required this.name,
    required this.type,
    required this.programId,
    required this.programName,
    required this.programCode,
  });

  @override
  List<Object?> get props => [levelId, levelNumber, name, type, programId, programName, programCode];
}
