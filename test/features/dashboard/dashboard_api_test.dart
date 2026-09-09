import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/error/app_failure.dart';
import 'package:learn_mobile/core/network/api_client.dart';
import 'package:learn_mobile/core/network/error_interceptor.dart';
import 'package:learn_mobile/features/dashboard/data/dashboard_api.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
  String? lastPath;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;

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

DashboardApi _apiWith(_StubAdapter adapter) {
  final dio =
      Dio(
          BaseOptions(
            baseUrl: 'https://lms.test/api/v1',
            validateStatus: (status) => status != null && status < 400,
          ),
        )
        ..httpClientAdapter = adapter
        ..interceptors.add(ErrorInterceptor());

  return DashboardApi(ApiClient(dio));
}

void main() {
  group('DashboardApi', () {
    test('membuka envelope dan mengembalikan isinya', () async {
      final adapter = _StubAdapter(200, {
        'response_code': 'success',
        'response_message': 'Berhasil',
        'response_data': {
          'courses': [
            {'id': 'c1', 'subject_name': 'Matematika', 'is_pinned': false},
          ],
        },
      });

      final dashboard = await _apiWith(adapter).fetch();

      expect(adapter.lastPath, '/dashboard');
      expect(dashboard.courses.single.subjectName, 'Matematika');
    });

    test('response_data yang tidak ada tidak membuatnya gagal', () async {
      final dashboard = await _apiWith(
        _StubAdapter(200, {
          'response_code': 'success',
          'response_message': 'Berhasil',
        }),
      ).fetch();

      expect(dashboard.courses, isEmpty);
    });

    test('kegagalan sampai sebagai AppFailure', () async {
      final call = _apiWith(
        _StubAdapter(500, {
          'response_code': 'server_error',
          'response_message': 'Server sibuk.',
        }),
      ).fetch();

      await expectLater(
        call,
        throwsA(
          isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Server sibuk.',
          ),
        ),
      );
    });
  });
}
