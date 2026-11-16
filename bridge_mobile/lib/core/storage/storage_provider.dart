import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provides a shared [FlutterSecureStorage] instance to any provider that needs
/// to read the JWT (e.g. the AuthInterceptor).
final secureStorageInstanceProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);
