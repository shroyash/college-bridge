import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_state.dart';
import 'institution_provider.dart';

/// StateNotifier for auth — orchestrates login/register flows.
/// Saves tokens to SecureStorage on success.
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final AuthRepository _authRepository;
  final SecureStorageService _storageService;
  final Ref _ref;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required AuthRepository authRepository,
    required SecureStorageService storageService,
    required Ref ref,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _authRepository = authRepository,
        _storageService = storageService,
        _ref = ref,
        super(const AuthInitial());

  Future<void> login({
    required String institutionCode,
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _loginUseCase(
        institutionCode: institutionCode,
        email: email,
        password: password,
      );
      await _storageService.saveTokens(
        accessToken: user.accessToken,
        refreshToken: user.refreshToken,
      );
      await _storageService.saveUserEmail(user.email);
      await _storageService.saveUserName(user.name);
      await _storageService.saveUserRole(user.role);
      if (user.institution != null) {
        await _storageService.saveInstitutionDetails(
          institutionId: user.institution!.institutionId,
          institutionCode: user.institution!.code,
          institutionName: user.institution!.name,
        );
        _ref.read(currentInstitutionProvider.notifier).updateInstitution(user.institution);
      }
      state = AuthSuccess(user);
    } on LoginFailureException catch (e) {
      // Typed reason-code failures from the backend
      state = AuthLoginFailure(
        reason: e.reason,
        message: e.message,
        rejectionReason: e.rejectionReason,
      );
    } catch (e) {
      state = AuthFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> register({
    required String institutionCode,
    required String name,
    required String email,
    required String password,
    required int levelId,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _registerUseCase(
        institutionCode: institutionCode,
        name: name,
        email: email,
        password: password,
        levelId: levelId,
      );
      await _storageService.saveTokens(
        accessToken: user.accessToken,
        refreshToken: user.refreshToken,
      );
      await _storageService.saveUserEmail(user.email);
      await _storageService.saveUserName(user.name);
      await _storageService.saveUserRole(user.role);
      if (user.institution != null) {
        await _storageService.saveInstitutionDetails(
          institutionId: user.institution!.institutionId,
          institutionCode: user.institution!.code,
          institutionName: user.institution!.name,
        );
        _ref.read(currentInstitutionProvider.notifier).updateInstitution(user.institution);
      }
      state = AuthSuccess(user);
    } catch (e) {
      state = AuthFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      // Best-effort: revoke the refresh token on the backend.
      // Failures are intentionally swallowed so the local logout always succeeds.
      try {
        await _authRepository.logout(refreshToken: refreshToken);
      } catch (_) {}
    }
    _ref.read(currentInstitutionProvider.notifier).clear();
    await _storageService.clearAll();
    state = const AuthInitial();
  }

  void reset() => state = const AuthInitial();
}
