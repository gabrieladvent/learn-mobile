import 'package:dio/dio.dart';

import '../error/app_failure.dart';
import 'api_envelope.dart';

/// Satu-satunya tempat error jaringan diterjemahkan jadi [AppFailure].
///
/// Kenapa di interceptor, bukan di tiap repository: kalau setiap pemanggilan
/// menangani error sendiri-sendiri, pasti ada yang terlewat — dan yang terlewat
/// itu muncul sebagai crash di HP siswa. Di sini, semuanya lewat satu pintu.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        // Dio akan MEMBUNGKUS ULANG ini jadi DioException apa pun yang kita
        // lakukan, jadi AppFailure-nya dititipkan di field `error`.
        // [ApiClient] yang membukanya kembali sebelum sampai ke repository.
        error: _toFailure(err),
      ),
    );
  }

  AppFailure _toFailure(DioException err) {
    // Tidak ada respons sama sekali = masalah koneksi, bukan masalah server.
    final isConnectionProblem = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };

    if (isConnectionProblem) return const NetworkFailure();

    final data = err.response?.data;

    // Jalur normal: backend membalas envelope, jadi kodenya bisa dibaca.
    if (data is Map<String, dynamic> && data.containsKey('response_code')) {
      return ApiEnvelope.fromJson(data).toFailure();
    }

    // Backend tidak membalas envelope — misal error di reverse proxy sebelum
    // permintaan sampai ke Laravel. Jatuh balik ke HTTP status.
    return switch (err.response?.statusCode) {
      401 => const UnauthenticatedFailure(),
      403 => const ForbiddenFailure(),
      404 => const NotFoundFailure(),
      409 => const ConflictFailure(),
      426 => const ClientTooOldFailure(),
      429 => const RateLimitedFailure(),
      _ => const ServerFailure(),
    };
  }
}
