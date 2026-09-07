import '../datasources/academic_admin_remote_datasource.dart';
import '../../domain/entities/academic_level.dart';
import '../../domain/entities/academic_program.dart';
import '../../domain/repositories/academic_admin_repository.dart';

class AcademicAdminRepositoryImpl implements AcademicAdminRepository {
  final AcademicAdminRemoteDataSource _remoteDataSource;

  const AcademicAdminRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<AcademicProgram>> getPrograms() => _remoteDataSource.getPrograms();

  @override
  Future<AcademicProgram> createProgram({required String name, required String code}) =>
      _remoteDataSource.createProgram(name: name, code: code);

  @override
  Future<void> deleteProgram(int programId) => _remoteDataSource.deleteProgram(programId);

  @override
  Future<List<AcademicLevel>> getLevels({required int programId}) =>
      _remoteDataSource.getLevels(programId: programId);

  @override
  Future<AcademicLevel> createLevel({
    required int programId,
    required int levelNumber,
    required String name,
    required String type,
  }) =>
      _remoteDataSource.createLevel(
        programId: programId,
        levelNumber: levelNumber,
        name: name,
        type: type,
      );

  @override
  Future<void> deleteLevel(int levelId) => _remoteDataSource.deleteLevel(levelId);
}
