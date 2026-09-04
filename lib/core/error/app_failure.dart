/// Satu tipe untuk SEMUA kegagalan yang bisa dilihat lapisan atas.
///
/// Kenapa ada: `DioException`, `SocketException`, dan `FormatException` adalah
/// urusan lapisan jaringan. Kalau tipe-tipe itu bocor ke UI, setiap layar harus
/// tahu cara menangani error HTTP — dan pasti ada yang terlewat.
/// Semua diterjemahkan sekali di [ErrorInterceptor] menjadi [AppFailure].
///
/// Ini `sealed class` bawaan Dart 3, bukan freezed — supaya kamu bisa membacanya
/// tanpa perlu tahu code generation. Keuntungan `sealed`: `switch` di bawah ini
/// WAJIB menangani semua kemungkinan. Kalau nanti ada jenis kegagalan baru,
/// compiler langsung menunjuk semua tempat yang belum menanganinya.
///
/// ```dart
/// final text = switch (failure) {
///   NetworkFailure()    => 'Tidak ada koneksi',
///   ValidationFailure() => failure.message,
///   _                   => failure.message,
/// };
/// ```
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  /// Kalimat yang aman ditampilkan ke siswa. Diambil dari `response_message`
  /// milik server kalau ada, karena server yang tahu konteksnya.
  final String message;
}

/// Tidak ada koneksi, atau permintaan kehabisan waktu.
class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet.']);
}

/// Token tidak valid atau sudah dicabut. Ditangani global: hapus token, ke login.
class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure([super.message = 'Sesi kamu sudah berakhir.']);
}

/// Siswa masih memakai password default. Ditangani global: paksa ke layar
/// ganti password. SENGAJA dibedakan dari [ForbiddenFailure] — perlakuannya
/// berlawanan meski HTTP status-nya sama-sama 403.
class PasswordChangeRequiredFailure extends AppFailure {
  const PasswordChangeRequiredFailure([super.message = 'Ganti password default kamu dulu.']);
}

/// Akun dinonaktifkan sekolah. Ditangani global: logout paksa.
class AccountInactiveFailure extends AppFailure {
  const AccountInactiveFailure([super.message = 'Akun kamu dinonaktifkan.']);
}

/// Tidak berhak mengakses data ini.
class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure([super.message = 'Kamu tidak punya akses ke data ini.']);
}

/// Data tidak ada, atau sudah dicabut guru. Pemanggil sebaiknya juga menghapus
/// salinan lokalnya — lihat docs/06.
class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Data tidak ditemukan.']);
}

/// State di server sudah berubah. Klien perlu memuat ulang, bukan menampilkan
/// error merah.
class ConflictFailure extends AppFailure {
  const ConflictFailure([super.message = 'Data sudah berubah. Muat ulang.']);
}

/// Validasi gagal. [fields] dipetakan langsung ke input form.
class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, this.fields);

  final Map<String, List<String>> fields;

  /// Pesan pertama untuk satu field, kalau ada.
  String? firstFor(String field) => fields[field]?.firstOrNull;
}

/// Versi aplikasi di bawah minimum. Ditangani global: layar force update.
class ClientTooOldFailure extends AppFailure {
  const ClientTooOldFailure([super.message = 'Perbarui aplikasi kamu dulu.']);
}

/// Kena rate limit. Pesannya sudah memuat sisa detik dari server.
class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure([super.message = 'Terlalu banyak percobaan.']);
}

/// Kesalahan di server, atau apa pun yang tidak dikenali.
class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Terjadi kesalahan di server.']);
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
