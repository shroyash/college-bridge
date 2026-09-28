import '../../domain/entities/academic_level.dart';

class AcademicLevelModel extends AcademicLevel {
  const AcademicLevelModel({
    required super.levelId,
    required super.levelNumber,
    required super.name,
    required super.type,
    required super.programId,
    required super.programName,
    required super.programCode,
  });

  factory AcademicLevelModel.fromJson(Map<String, dynamic> json) {
    return AcademicLevelModel(
      levelId: (json['levelId'] as num?)?.toInt() ?? 0,
      levelNumber: (json['levelNumber'] as num?)?.toInt() ?? 1,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'SEMESTER',
      programId: (json['programId'] as num?)?.toInt() ?? 0,
      programName: json['programName'] as String? ?? '',
      programCode: json['programCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'levelNumber': levelNumber,
      'name': name,
      'type': type,
      'programId': programId,
      'programName': programName,
      'programCode': programCode,
    };
  }
}
