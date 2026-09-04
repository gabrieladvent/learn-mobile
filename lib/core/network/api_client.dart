import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../error/app_failure.dart';
import 'dio_provider.dart';

part 'api_client.g.dart';

/// Pembungkus tipis di atas Dio yang MELEPAS [AppFailure] dari bungkus
/// [DioException].
///
/// Kenapa ini perlu: Dio selalu membungkus ulang apa pun yang dilempar
/// interceptor menjadi DioException — lihat `DioMixin.assureDioException()`
/// di dio 5.11.1. Jadi meski [ErrorInterceptor] sudah menerjemahkan kegagalan
/// jadi AppFailure, pemanggil tetap menerima DioException, dan setiap
/// `on AppFailure catch` di lapisan atas tidak pernah cocok. Akibatnya galat
/// lolos jadi unhandled exception.
///
/// Semua kelas `*Api` menerima ApiClient, BUKAN Dio. Itu disengaja: tidak ada
/// jalan untuk tanpa sengaja memakai Dio langsung dan melewati pelepasan ini.
class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  /// Jalan keluar untuk hal yang butuh Dio apa adanya — misalnya mengunduh
  /// berkas dengan indikator progres. Pemakainya wajib melepas AppFailure
  /// sendiri.
  Dio get raw => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _unwrap(() => _dio.get<T>(path, queryParameters: query));

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _unwrap(() => _dio.post<T>(path, data: data));

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _unwrap(() => _dio.patch<T>(path, data: data));

  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      _unwrap(() => _dio.delete<T>(path, data: data));

  Future<T> _unwrap<T>(Future<T> Function() send) async {
    try {
      return await send();
    } on DioException catch (error, stackTrace) {
      final failure = error.error;

      // ErrorInterceptor selalu menaruh AppFailure di sini. Kalau ternyata
      // bukan, JANGAN ditelan — biarkan naik apa adanya supaya bugnya kelihatan
      // alih-alih menyamar jadi kegagalan jaringan biasa.
      if (failure is! AppFailure) rethrow;

      // Melempar ulang dengan jejak tumpukan aslinya, bukan `throw failure`
      // biasa — kalau tidak, jejaknya terpotong sampai baris ini saja dan
      // pemanggil yang sebenarnya hilang dari laporan galat.
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }
}

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) => ApiClient(ref.watch(dioProvider));
