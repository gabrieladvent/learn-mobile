sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet.']);
}

class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure([super.message = 'Sesi kamu sudah berakhir.']);
}

class PasswordChangeRequiredFailure extends AppFailure {
  const PasswordChangeRequiredFailure([
    super.message = 'Ganti password default kamu dulu.',
  ]);
}

class AccountInactiveFailure extends AppFailure {
  const AccountInactiveFailure([super.message = 'Akun kamu dinonaktifkan.']);
}

class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure([
    super.message = 'Kamu tidak punya akses ke data ini.',
  ]);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Data tidak ditemukan.']);
}

class ConflictFailure extends AppFailure {
  const ConflictFailure([super.message = 'Data sudah berubah. Muat ulang.']);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, this.fields);

  final Map<String, List<String>> fields;

  String? firstFor(String field) => fields[field]?.firstOrNull;
}

class ClientTooOldFailure extends AppFailure {
  const ClientTooOldFailure([super.message = 'Perbarui aplikasi kamu dulu.']);
}

class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure([super.message = 'Terlalu banyak percobaan.']);
}

class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Terjadi kesalahan di server.']);
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
