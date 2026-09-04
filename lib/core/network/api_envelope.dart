import '../error/app_failure.dart';

/// Pembungkus response backend (ADR-0016).
///
/// Setiap response `/api/v1` — sukses maupun gagal — berbentuk sama:
///
/// ```json
/// { "response_code": "success", "response_message": "Berhasil", "response_data": { } }
/// { "response_code": "validation_failed", "response_message": "..." }
/// ```
///
/// `response_data` DIHILANGKAN kalau tidak ada isinya, jadi jangan
/// mengasumsikan field itu selalu ada.
class ApiEnvelope {
  const ApiEnvelope({required this.code, required this.message, this.data});

  /// Kode mesin, bukan HTTP status. `403` bisa berarti "password masih default"
  /// atau "bukan kelasmu" — dua hal yang perlakuannya berlawanan. Kode inilah
  /// yang membedakannya. JANGAN pernah mencocokkan [message] untuk mengambil
  /// keputusan; kalimatnya bisa diubah kapan saja tanpa memberi tahu kita.
  final String code;

  /// Kalimat berbahasa Indonesia untuk ditampilkan ke siswa.
  final String message;

  final Map<String, dynamic>? data;

  static ApiEnvelope fromJson(Map<String, dynamic> json) {
    final rawData = json['response_data'];

    return ApiEnvelope(
      code: json['response_code'] as String? ?? 'server_error',
      message: json['response_message'] as String? ?? 'Terjadi kesalahan.',
      data: rawData is Map<String, dynamic> ? rawData : null,
    );
  }

  /// Menerjemahkan `response_code` menjadi [AppFailure].
  ///
  /// Kode yang tidak dikenal sengaja jatuh ke [ServerFailure] dengan pesan dari
  /// server — aplikasi TIDAK boleh crash hanya karena backend menambah kode baru.
  AppFailure toFailure() {
    return switch (code) {
      'unauthenticated' => UnauthenticatedFailure(message),
      'password_change_required' => PasswordChangeRequiredFailure(message),
      'account_inactive' => AccountInactiveFailure(message),
      'forbidden' => ForbiddenFailure(message),
      'not_found' => NotFoundFailure(message),
      'conflict' => ConflictFailure(message),
      'client_too_old' => ClientTooOldFailure(message),
      'too_many_requests' => RateLimitedFailure(message),
      'validation_failed' => ValidationFailure(message, _fields()),
      _ => ServerFailure(message),
    };
  }

  /// Detail validasi per input ada di `response_data.fields`.
  Map<String, List<String>> _fields() {
    final raw = data?['fields'];
    if (raw is! Map) return const {};

    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        (value is List ? value : [value]).map((e) => e.toString()).toList(),
      ),
    );
  }
}
