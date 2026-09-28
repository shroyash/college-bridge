abstract class ApiEndpoints {
  // Base configuration
  static const String baseUrl = 'http://localhost:8080';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // --- AUTHENTICATION & PASSWORD ENDPOINTS ---
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refreshToken = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  static const String forgotPassword = '/api/auth/password/forgot';
  static const String verifyPasswordOtp = '/api/auth/password/verify-otp';
  static const String resendPasswordOtp = '/api/auth/password/resend-otp';
  static const String resetPassword = '/api/auth/password/reset';

  // --- OTP ENDPOINTS ---
  static const String sendOtp = '/api/otp/send';
  static const String verifyOtp = '/api/otp/verify';

  // --- ACCOUNT ENDPOINTS ---
  static const String accountProfile = '/api/account/profile';
  static const String accountChangePassword = '/api/account/password/change';
  static const String accountInitiateEmailChange = '/api/account/email/initiate';
  static const String accountConfirmEmailChange = '/api/account/email/confirm';
  static const String accountUploadProfileImage = '/api/account/profile/image';
  static const String accountDelete = '/api/account';

  // --- FILE STORAGE ENDPOINTS ---
  static const String filesUpload = '/api/files/upload';
  static String filesDownload(String fileName) => '/api/files/download/$fileName';

  // --- INSTITUTION REGISTRATION (PUBLIC) ---
  static const String institutionRegister = '/api/auth/register-institution';

  // --- INSTITUTION ADMIN ---
  static const String adminInstitutionProfile = '/api/admin/institution/profile';

  // --- PUBLIC ACADEMIC LOOKUP ---
  static String publicInstitutionPrograms(String code) =>
      '/api/public/academic/institutions/$code/programs';
  static String publicProgramLevels(int programId) =>
      '/api/public/academic/pograms/$programId/levels';

  // --- ACADEMIC STRUCTURE (ADMIN) ---
  static const String adminAcademicPrograms = '/api/admin/academic/programs';
  static String adminAcademicProgramDetails(int id) =>
      '/api/admin/academic/programs/$id';
  static String adminAcademicProgramLevels(int programId) =>
      '/api/admin/academic/programs/$programId/levels';
  static const String adminAcademicLevels = '/api/admin/academic/levels';
  static String adminAcademicLevelDetails(int id) =>
      '/api/admin/academic/levels/$id';
  static const String adminAcademicSubjects = '/api/admin/academic/subjects';
  static String adminAcademicSubjectDetails(int id) =>
      '/api/admin/academic/subjects/$id';
  static const String adminAcademicSubjectsBatch =
      '/api/admin/academic/subjects/batch';

  // --- STUDENT COHORT & MANAGEMENT (ADMIN) ---
  static const String adminStudents = '/api/admin/students';
  static const String adminStudentsFilterOptions =
      '/api/admin/students/filter-options';
  static const String adminStudentsBulkTransfer =
      '/api/admin/students/bulk-transfer';
  static String adminStudentLevelAssign(int levelId, int studentId) =>
      '/api/admin/students/levels/$levelId/students/$studentId';
  static const String adminUnassignedStudents =
      '/api/admin/students/unassigned-students';

  // --- ADMIN USERS & TEACHERS ---
  static const String adminUsers = '/api/admin/users';
  static const String adminUsersSearch = '/api/admin/users/search';
  static const String adminUsersFilter = '/api/admin/users/filter';
  static String adminUserSuspend(int id) => '/api/admin/users/$id/suspend';
  static String adminUserActivate(int id) => '/api/admin/users/$id/activate';
  static String adminUserRole(int id) => '/api/admin/users/$id/role';

  static const String adminTeachers = '/api/admin/teachers';
  static String adminTeacherDetails(int id) => '/api/admin/teachers/$id';
  static String adminTeacherSubjectAssignments(int teacherId) =>
      '/api/admin/teachers/$teacherId/subject-assignments';
  static String adminTeacherSubjectAssignmentDetails(
          int teacherId, int assignmentId) =>
      '/api/admin/teachers/$teacherId/subject-assignments/$assignmentId';

  // --- SUBJECTS (PUBLIC / USER-FACING) ---
  static String subjectDetails(int id) => '/api/academic/subjects/$id/details';
  static const String mySubjects = '/api/academic/subjects/my-subjects';
  static const String academicSubjectsAll = '/api/academic/subjects/all';
  static const String academicSubjectsSearch = '/api/academic/subjects/search';
  static String academicStudentSubjects(int studentId) =>
      '/api/academic/subjects/student/$studentId';

  // --- DASHBOARD ENDPOINTS ---
  static const String adminDashboard = '/api/admin/dashboard';
  static const String superAdminDashboard = '/api/super-admin/dashboard';

  // --- SUPER ADMIN ENDPOINTS ---
  static const String superAdminInstitutions = '/api/super-admin/institutions';
  static const String superAdminInstitutionsPending =
      '/api/super-admin/institutions/pending';
  static String superAdminInstitutionApprove(int id) =>
      '/api/super-admin/institutions/$id/approve';
  static String superAdminInstitutionReject(int id) =>
      '/api/super-admin/institutions/$id/reject';
  static String superAdminInstitutionSuspend(int id) =>
      '/api/super-admin/institutions/$id/suspend';
  static String superAdminInstitutionReactivate(int id) =>
      '/api/super-admin/institutions/$id/reactivate';

  static const String superAdminUsers = '/api/super-admin/users';
  static const String superAdminAdmins = '/api/super-admin/admins';
  static String superAdminUserSuspend(int id) =>
      '/api/super-admin/users/$id/suspend';
  static String superAdminUserActivate(int id) =>
      '/api/super-admin/users/$id/activate';
}
