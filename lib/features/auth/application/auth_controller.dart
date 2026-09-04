import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

part 'auth_controller.g.dart';

/// Lapisan `application`: menjembatani UI dan repository.
///
/// Kelas ini memegang "siapa yang sedang login" untuk seluruh aplikasi, dan
/// router membaca nilai ini untuk memutuskan layar mana yang boleh dibuka.
///
/// Tipenya `AsyncValue<AuthSession?>` — tiga keadaan sekaligus:
///   loading → sedang memeriksa token tersimpan (layar splash)
///   data(null) → belum login
///   data(sesi) → sudah login
///   error → gagal memulihkan sesi
///
/// Tidak perlu bikin enum status sendiri; ini bawaan Riverpod.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  /// `build` dipanggil sekali saat provider pertama dibaca. Nilai baliknya
  /// jadi state awal. Karena `Future`, Riverpod otomatis membungkusnya
  /// jadi `AsyncValue` — loading dulu, lalu data atau error.
  @override
  Future<AuthSession?> build() {
    return ref.watch(authRepositoryProvider).restore();
  }

  Future<void> login({required String nisn, required String password}) async {
    // SENGAJA TIDAK menyetel `state = AsyncValue.loading()` di sini.
    //
    // State ini menjawab pertanyaan "siapa yang sedang login", dan router
    // memakai `isLoading`-nya sebagai penanda "masih memulihkan token → tampilkan
    // splash". Kalau login ikut menyetel loading, menekan tombol Masuk akan
    // melempar siswa ke layar splash di tengah proses.
    //
    // "Sedang mengirim formulir" itu keadaan milik layar, bukan milik aplikasi —
    // jadi tempatnya di LoginScreen, bukan di sini.

    // `AsyncValue.guard` menangkap exception dan mengubahnya jadi AsyncError,
    // jadi tidak perlu try/catch manual. Kegagalan sudah berbentuk AppFailure
    // berkat ErrorInterceptor.
    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).login(
            nisn: nisn,
            password: password,
            deviceName: 'mobile',
          );
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();

    // Set langsung, tanpa memuat ulang dari server — siswa harus langsung
    // keluar meski jaringannya bermasalah.
    state = const AsyncValue.data(null);
  }

  /// Ganti password, lalu lepaskan guard router.
  ///
  /// Sama seperti login: TIDAK menyetel loading global. Kegagalan dibiarkan
  /// naik ke layar sebagai [AppFailure] supaya pesan galat per-field dari
  /// server bisa ditempel ke input yang tepat.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ref.read(authRepositoryProvider).changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );

    markPasswordChanged();
  }

  /// Dipanggil setelah ganti password berhasil, supaya guard router melepas
  /// siswa dari layar ganti password.
  void markPasswordChanged() {
    final session = state.value;
    if (session == null) return;

    state = AsyncValue.data(session.copyWith(mustChangePassword: false));
  }
}
