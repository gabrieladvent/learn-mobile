import 'package:dio/dio.dart';

import '../error/app_failure.dart';
import '../update/force_update_info.dart';
import 'api_envelope.dart';

/// Satu-satunya tempat error jaringan diterjemahkan jadi [AppFailure].
///
/// Kenapa di interceptor, bukan di tiap repository: kalau setiap pemanggilan
/// menangani error sendiri-sendiri, pasti ada yang terlewat — dan yang terlewat
/// itu muncul sebagai crash di HP siswa. Di sini, semuanya lewat satu pintu.
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({this.onClientTooOld});

  final void Function(ForceUpdateInfo info)? onClientTooOld;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = _toFailure(err);

    if (failure is ClientTooOldFailure) {
      onClientTooOld?.call(
        ForceUpdateInfo.fromResponse(failure.message, _envelopeData(err)),
      );
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: failure,
      ),
    );
  }

  AppFailure _toFailure(DioException err) {
    final isConnectionProblem = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };

    if (isConnectionProblem) return const NetworkFailure();

    final envelope = _envelope(err);

    if (envelope != null) return envelope.toFailure();

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

  ApiEnvelope? _envelope(DioException err) {
    final data = err.response?.data;

    if (data is Map<String, dynamic> && data.containsKey('response_code')) {
      return ApiEnvelope.fromJson(data);
    }

    return null;
  }

  Map<String, dynamic>? _envelopeData(DioException err) => _envelope(err)?.data;
}
