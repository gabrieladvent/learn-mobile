import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_session.dart';
import '../domain/student.dart';
import 'auth_api.dart';

part 'auth_repository.g.dart';

/// Repository = tempat KEBIJAKAN diputuskan.
///
/// [AuthApi] tahu cara memanggil endpoint; repository yang memutuskan token
/// disimpan ke mana, kapan dihapus, dan apa yang terjadi kalau token ternyata
/// sudah tidak berlaku. Nanti kebijakan cache dan outbox juga tinggal di sini,
/// bukan di provider maupun di layar.
class AuthRepository {
  const AuthRepository(this._api, this._tokens);

  final AuthApi _api;
  final TokenStorage _tokens;

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

    // Token disimpan DULU: permintaan berikutnya butuh header Authorization.
    await _tokens.write(token);

    return AuthSession(
      token: token,
      student: Student.fromJson(data['student'] as Map<String, dynamic>),
      mustChangePassword: data['must_change_password'] as bool? ?? false,
    );
  }

  /// Memulihkan sesi saat aplikasi dibuka.
  ///
  /// Mengembalikan `null` kalau memang belum pernah login. Token yang ternyata
  /// sudah dicabut server (401) dianggap sama dengan belum login — tokennya
  /// dibuang supaya tidak dipakai lagi.
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
    // Kegagalan jaringan SENGAJA dibiarkan naik. Nanti saat cache offline
    // dibangun (docs/06), sesi lama dipakai supaya siswa tetap bisa membuka
    // materi yang sudah pernah diunduh tanpa sinyal.
  }

  /// Ganti password. Token TIDAK berubah — server tetap menerima token yang
  /// sama setelah password diganti, jadi siswa tidak perlu login ulang.
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
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(tokenStorageProvider),
  );
}
