import 'package:freezed_annotation/freezed_annotation.dart';

import 'student.dart';

part 'auth_session.freezed.dart';

/// Sesi login yang sedang aktif.
///
/// Tidak punya `fromJson` karena tidak pernah datang utuh dari satu response:
/// token disimpan di secure storage, sedangkan profilnya dimuat ulang lewat
/// `GET /auth/me` saat aplikasi dibuka.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String token,
    required Student student,

    /// `true` selama `password_changed_at` di server masih null.
    ///
    /// Selama ini `true`, backend MENOLAK semua endpoint konten dengan
    /// `password_change_required`. Jadi router harus menahan siswa di layar
    /// ganti password — kalau tidak, dia akan menabrak error di setiap layar
    /// tanpa tahu jalan keluarnya.
    required bool mustChangePassword,
  }) = _AuthSession;
}
