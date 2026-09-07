import 'package:equatable/equatable.dart';

/// Domain entity for a Subject in the normalized hierarchy.
/// Maps to backend SubjectResponse: { subjectId, name, code, creditHours, levelId, levelName, programName }
class Subject extends Equatable {
  final int subjectId;
  final String name;
  final String? code;
  final int creditHours;
  final int levelId;
  final String levelName;
  final String programName;
  final String? teacherName;

  const Subject({
    required this.subjectId,
    required this.name,
    this.code,
    required this.creditHours,
    required this.levelId,
    required this.levelName,
    required this.programName,
    this.teacherName,
  });

  // Backwards compatibility getters
  String get faculty => programName;
  int get semester {
    final match = RegExp(r'\d+').firstMatch(levelName);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? levelId;
    }
    return levelId;
  }

  @override
  List<Object?> get props => [subjectId, name, code, creditHours, levelId, levelName, programName, teacherName];
}

