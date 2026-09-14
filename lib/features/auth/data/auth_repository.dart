import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/cache/cache_store.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_session.dart';
import '../domain/student.dart';
import 'auth_api.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  const AuthRepository(this._api, this._tokens, this._cache);

  final AuthApi _api;
  final TokenStorage _tokens;
  final CacheStore _cache;

  Future<AuthSession> login({
    required String nisn,
    required String password,
    required String deviceName,
  }) async {
    final data = await _api.login(
      nisn: nisn,
      password: password,
      deviceName: deviceName,
    );

    final token = data['token'] as String;

    await _tokens.write(token);

    return AuthSession(
      token: token,
      student: Student.fromJson(data['student'] as Map<String, dynamic>),
      mustChangePassword: data['must_change_password'] as bool? ?? false,
    );
  }

  Future<AuthSession?> restore() async {
    final token = await _tokens.read();
    if (token == null) return null;

    try {
      final data = await _api.me();

      return AuthSession(
        token: token,
        student: Student.fromJson(data['student'] as Map<String, dynamic>),
        mustChangePassword: data['must_change_password'] as bool? ?? false,
      );
    } on UnauthenticatedFailure {
      await _tokens.clear();
      return null;
    } on AccountInactiveFailure {
      await _tokens.clear();
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } on AppFailure {
      // Server tidak terjangkau? Tetap lanjut menghapus token lokal.
      // Membiarkan siswa "gagal logout" karena sinyal jelek jauh lebih buruk
      // daripada token yang menggantung di server sampai kedaluwarsa.
    } finally {
      await _tokens.clear();
      // Cache ikut dibuang. Satu HP di rumah bisa dipakai bergantian oleh
      // kakak-adik yang sama-sama siswa — beranda milik orang sebelumnya tidak
      // boleh sempat terlihat sedetik pun oleh yang login berikutnya.
      await _cache.clear();
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(cacheStoreProvider),
  );
}
