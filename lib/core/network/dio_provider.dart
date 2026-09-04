import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

part 'dio_provider.g.dart';

/// Satu instance [Dio] untuk seluruh aplikasi.
///
/// URUTAN interceptor penting dan disengaja:
///   1. [AuthInterceptor]  — menempel token sebelum permintaan dikirim
///   2. [ErrorInterceptor] — menerjemahkan kegagalan setelah respons datang
///
/// SENGAJA TIDAK ADA retry otomatis di sini. Mengulang permintaan POST secara
/// diam-diam akan menduplikasi pengumpulan tugas siswa. Pengulangan hanya boleh
/// lewat outbox yang membawa `idempotency_key` (ADR-0008).
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.current.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      // Jangan lempar exception untuk 4xx — biar ErrorInterceptor yang
      // menerjemahkannya jadi AppFailure dengan pesan dari server.
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(ref.watch(tokenStorageProvider), '1.0.0+1'),
    ErrorInterceptor(),
  ]);

  return dio;
}
