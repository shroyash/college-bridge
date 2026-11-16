import '../../domain/entities/academic_program.dart';

class AcademicProgramModel extends AcademicProgram {
  const AcademicProgramModel({
    required super.programId,
    required super.name,
    required super.code,
  });

  factory AcademicProgramModel.fromJson(Map<String, dynamic> json) {
    return AcademicProgramModel(
      programId: (json['programId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'programId': programId,
      'name': name,
      'code': code,
    };
  }
}
