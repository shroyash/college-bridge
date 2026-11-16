import 'package:equatable/equatable.dart';
import '../../../dashboard/domain/entities/subject.dart';
import '../../domain/entities/academic_level.dart';
import '../../domain/entities/academic_program.dart';

class AcademicManagementState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  // Programs (formerly faculties)
  final List<AcademicProgram> programs;
  final AcademicProgram? selectedProgram;

  // Levels (formerly semesters/academic classes)
  final List<AcademicLevel> levels;
  final AcademicLevel? selectedLevel;
  final bool loadingLevels;

  // Subjects for selected level
  final List<Subject> subjects;

  const AcademicManagementState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.programs = const [],
    this.selectedProgram,
    this.levels = const [],
    this.selectedLevel,
    this.loadingLevels = false,
    this.subjects = const [],
  });

  AcademicManagementState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    List<AcademicProgram>? programs,
    AcademicProgram? selectedProgram,
    List<AcademicLevel>? levels,
    AcademicLevel? selectedLevel,
    bool? loadingLevels,
    List<Subject>? subjects,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearSelectedProgram = false,
    bool clearSelectedLevel = false,
  }) {
    return AcademicManagementState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      programs: programs ?? this.programs,
      selectedProgram: clearSelectedProgram ? null : (selectedProgram ?? this.selectedProgram),
      levels: levels ?? this.levels,
      selectedLevel: clearSelectedLevel ? null : (selectedLevel ?? this.selectedLevel),
      loadingLevels: loadingLevels ?? this.loadingLevels,
      subjects: subjects ?? this.subjects,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        errorMessage,
        successMessage,
        programs,
        selectedProgram,
        levels,
        selectedLevel,
        loadingLevels,
        subjects,
      ];
}
