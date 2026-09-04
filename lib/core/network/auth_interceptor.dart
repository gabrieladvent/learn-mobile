import 'dart:io';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Menempelkan token dan identitas klien ke SETIAP permintaan.
///
/// Kalau ini dikerjakan manual di tiap pemanggilan API, cepat atau lambat ada
/// satu endpoint yang lupa — dan gagalnya muncul sebagai 401 yang membingungkan.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens, this._appVersion);

  final TokenStorage _tokens;

  /// Format `versionName+buildNumber`, dipakai backend untuk force update
  /// (ADR-0013). Backend membalas 426 kalau versinya di bawah minimum.
  final String _appVersion;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.read();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    options.headers['Accept'] = 'application/json';
    options.headers['X-Client-Version'] = _appVersion;
    options.headers['X-Client-Platform'] = Platform.isIOS ? 'ios' : 'android';

    handler.next(options);
  }
}
