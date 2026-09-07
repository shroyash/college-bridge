import '../../core/constants/api_endpoints.dart';

/// Legacy adapter for [ApiEndpoints] to maintain backward compatibility across existing features
abstract class ApiConstants {
  static const String baseUrl = ApiEndpoints.baseUrl;
  static const Duration connectTimeout = ApiEndpoints.connectTimeout;
  static const Duration receiveTimeout = ApiEndpoints.receiveTimeout;

  static const String login = ApiEndpoints.login;
  static const String register = ApiEndpoints.register;
  static const String refreshToken = ApiEndpoints.refreshToken;
  static const String logout = ApiEndpoints.logout;
  static const String forgotPassword = ApiEndpoints.forgotPassword;
  static const String verifyOtp = ApiEndpoints.verifyPasswordOtp;
  static const String resendOtp = ApiEndpoints.resendPasswordOtp;
  static const String resetPassword = ApiEndpoints.resetPassword;

  static const String institutionRegister = ApiEndpoints.institutionRegister;

  static String publicInstitutionPrograms(String code) =>
      ApiEndpoints.publicInstitutionPrograms(code);
  static String publicProgramLevels(int programId) =>
      ApiEndpoints.publicProgramLevels(programId);

  static const String superAdminDashboardInstTotal = ApiEndpoints.superAdminDashboard;
  static const String superAdminDashboardInstPending = ApiEndpoints.superAdminDashboard;
  static const String superAdminDashboardInstActive = ApiEndpoints.superAdminDashboard;
  static const String superAdminDashboardInstSuspended = ApiEndpoints.superAdminDashboard;
  static const String superAdminDashboardUsersTotal = ApiEndpoints.superAdminDashboard;
  static const String superAdminDashboardUsersStudents = ApiEndpoints.superAdminDashboard;
  static const String superAdminDashboardUsersTeachers = ApiEndpoints.superAdminDashboard;
  static const String superAdminDashboardUsersAdmins = ApiEndpoints.superAdminDashboard;

  static const String superAdminInstitutionsPending = ApiEndpoints.superAdminInstitutionsPending;
  static const String superAdminInstitutions = ApiEndpoints.superAdminInstitutions;
  static const String superAdminUsers = ApiEndpoints.superAdminUsers;
  static const String superAdminAdmins = ApiEndpoints.superAdminAdmins;

  static const String adminDashboard = ApiEndpoints.adminDashboard;

  static const String adminUsersFilter = ApiEndpoints.adminUsersFilter;
  static const String adminUsersSearch = ApiEndpoints.adminUsersSearch;
  static const String adminUsers = ApiEndpoints.adminUsers;
  static const String adminTeachers = ApiEndpoints.adminTeachers;
  static const String adminTeacherAssignments = ApiEndpoints.adminTeachers;
  static const String adminStudents = ApiEndpoints.adminStudents;
  static const String adminStudentsFilterOptions = ApiEndpoints.adminStudentsFilterOptions;
  static const String adminStudentsBulkTransfer = ApiEndpoints.adminStudentsBulkTransfer;

  static const String mySubjects = ApiEndpoints.mySubjects;
  static const String academicSubjectsAll = ApiEndpoints.academicSubjectsAll;
  static const String academicSubjectsSearch = ApiEndpoints.academicSubjectsSearch;
  static const String academicStudentSubjects = ApiEndpoints.adminStudents;

  static const String adminAcademicPrograms = ApiEndpoints.adminAcademicPrograms;
  static const String adminAcademicLevels = ApiEndpoints.adminAcademicLevels;
  static const String adminAcademicSubjects = ApiEndpoints.adminAcademicSubjects;
  static const String adminAcademicSubjectsBatch = ApiEndpoints.adminAcademicSubjectsBatch;

  static const String teacherMyClasses = ApiEndpoints.mySubjects;
  static const String teacherClassDetails = ApiEndpoints.adminAcademicLevels;
  static const String teacherMySubjects = ApiEndpoints.mySubjects;
  static const String teacherSubjectDetails = ApiEndpoints.adminAcademicSubjects;

  static const String studentClassDetails = ApiEndpoints.adminAcademicLevels;
  static const String studentSubjectDetails = ApiEndpoints.mySubjects;
}
