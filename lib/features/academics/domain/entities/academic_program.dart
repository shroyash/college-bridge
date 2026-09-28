import 'package:equatable/equatable.dart';

/// Domain entity for an Academic Program (e.g., BCA, BBA, BSC-CSIT).
class AcademicProgram extends Equatable {
  final int programId;
  final String name;
  final String code;

  const AcademicProgram({
    required this.programId,
    required this.name,
    required this.code,
  });

  @override
  List<Object?> get props => [programId, name, code];
}
