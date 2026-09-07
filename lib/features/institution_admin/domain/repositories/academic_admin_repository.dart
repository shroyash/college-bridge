import '../entities/academic_level.dart';
import '../entities/academic_program.dart';

/// Normalized repository abstraction for academic management.
/// Replaces the legacy class-centric API surface.
abstract class AcademicAdminRepository {
  // Programs (formerly faculties)
  Future<List<AcademicProgram>> getPrograms();
  Future<AcademicProgram> createProgram({required String name, required String code});
  Future<void> deleteProgram(int programId);

  // Levels (formerly semesters/classes)
  Future<List<AcademicLevel>> getLevels({required int programId});
  Future<AcademicLevel> createLevel({
    required int programId,
    required int levelNumber,
    required String name,
    required String type,
  });
  Future<void> deleteLevel(int levelId);
}
