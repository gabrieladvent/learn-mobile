import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/error/app_failure.dart';
import 'package:learn_mobile/core/network/api_client.dart';
import 'package:learn_mobile/core/network/error_interceptor.dart';

/// Adapter palsu: mengembalikan respons yang sudah ditentukan tanpa jaringan.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter.responds(this.statusCode, this.body) : throwing = null;
  _StubAdapter.fails(this.throwing) : statusCode = 0, body = const {};

  final int statusCode;
  final Map<String, dynamic> body;
  final Object? throwing;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final error = throwing;
    if (error != null) throw error;

    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _clientThat(HttpClientAdapter adapter) {
  final dio =
      Dio(
          BaseOptions(
            baseUrl: 'https://contoh.test/api/v1',
            validateStatus: (status) => status != null && status < 400,
          ),
        )
        ..httpClientAdapter = adapter
        ..interceptors.add(ErrorInterceptor());

  return ApiClient(dio);
}

void main() {
  group('ApiClient', () {
    test('melempar AppFailure, BUKAN DioException', () async {
      // Regresi untuk bug nyata: Dio selalu membungkus ulang apa pun yang
      // dilempar interceptor jadi DioException. Tanpa pelepasan di ApiClient,
      // setiap `on AppFailure catch` di lapisan atas tidak pernah cocok dan
      // galatnya lolos jadi unhandled exception di layar siswa.
      final client = _clientThat(
        _StubAdapter.responds(422, {
          'response_code': 'validation_failed',
          'response_message': 'Data tidak valid.',
          'response_data': {
            'fields': {
              'current_password': ['Password saat ini tidak sesuai.'],
            },
          },
        }),
      );

      await expectLater(
        client.patch<Map<String, dynamic>>('/profile/password'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.firstFor('current_password'),
            'pesan per-field',
            'Password saat ini tidak sesuai.',
          ),
        ),
      );
    });

    test('membedakan password_change_required dari forbidden biasa', () async {
      final client = _clientThat(
        _StubAdapter.responds(403, {
          'response_code': 'password_change_required',
          'response_message': 'Ganti password dulu.',
        }),
      );

      await expectLater(
        client.get<Map<String, dynamic>>('/dashboard'),
        throwsA(isA<PasswordChangeRequiredFailure>()),
      );
    });

    test('masalah koneksi jadi NetworkFailure', () async {
      final client = _clientThat(
        _StubAdapter.fails(
          DioException.connectionError(
            requestOptions: RequestOptions(path: '/auth/me'),
            reason: 'tidak ada rute ke host',
          ),
        ),
      );

      await expectLater(
        client.get<Map<String, dynamic>>('/auth/me'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
