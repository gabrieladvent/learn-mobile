import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/error/app_failure.dart';
import 'package:learn_mobile/core/network/error_interceptor.dart';
import 'package:learn_mobile/core/update/force_update_info.dart';

/// Adapter palsu: membalas apa pun dengan satu respons yang sudah ditentukan.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode, this.body);

  final int statusCode;
  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

/// Menjalankan satu permintaan lewat [ErrorInterceptor] dan mengembalikan
/// laporan force update yang tertangkap — `null` kalau tidak ada.
Future<List<ForceUpdateInfo>> _reportsFrom(int statusCode, Object body) async {
  final reports = <ForceUpdateInfo>[];

  final dio =
      Dio(
          BaseOptions(
            baseUrl: 'https://contoh.test/api/v1',
            validateStatus: (status) => status != null && status < 400,
          ),
        )
        ..httpClientAdapter = _StubAdapter(statusCode, body)
        ..interceptors.add(ErrorInterceptor(onClientTooOld: reports.add));

  try {
    await dio.get<dynamic>('/dashboard');
  } on DioException catch (_) {
    // Kegagalannya memang yang diharapkan; yang diuji laporannya.
  }

  return reports;
}

void main() {
  group('ErrorInterceptor → force update', () {
    test('426 dengan envelope lengkap melaporkan detail dari server', () async {
      final reports = await _reportsFrom(426, {
        'response_code': 'client_too_old',
        'response_message': 'Versi aplikasi kamu sudah terlalu lama.',
        'response_data': {
          'min_version': '1.4.0',
          'store_url': 'https://play.google.com/store/apps/details?id=x',
        },
      });

      expect(reports, hasLength(1));
      expect(reports.single.message, 'Versi aplikasi kamu sudah terlalu lama.');
      expect(reports.single.minVersion, '1.4.0');
      expect(
        reports.single.storeUrl,
        'https://play.google.com/store/apps/details?id=x',
      );
    });

    test('426 tanpa envelope tetap melaporkan penolakan', () async {
      // Bisa terjadi kalau penolakan datang dari reverse proxy, sebelum
      // permintaan sampai ke Laravel. Layar force update harus tetap muncul.
      final reports = await _reportsFrom(426, 'Upgrade Required');

      expect(reports, hasLength(1));
      expect(reports.single.minVersion, isNull);
      expect(
        reports.single.storeUrl,
        isNull,
        reason: 'Tanpa store_url, layar menampilkan petunjuk manual.',
      );
    });

    test('detail bertipe aneh diperlakukan sebagai tidak ada', () async {
      final reports = await _reportsFrom(426, {
        'response_code': 'client_too_old',
        'response_message': 'Perbarui aplikasi kamu dulu.',
        'response_data': {'min_version': 140, 'store_url': ''},
      });

      expect(reports.single.minVersion, isNull);
      expect(reports.single.storeUrl, isNull);
    });

    test('kegagalan lain tidak memicu force update', () async {
      final reports = await _reportsFrom(401, {
        'response_code': 'unauthenticated',
        'response_message': 'Sesi kamu sudah berakhir.',
      });

      expect(reports, isEmpty);
    });

    test('426 tetap sampai ke pemanggil sebagai ClientTooOldFailure', () async {
      // Laporan global TIDAK menggantikan penanganan error biasa: layar yang
      // memicunya tetap perlu tahu permintaannya gagal.
      final dio =
          Dio(
              BaseOptions(
                baseUrl: 'https://contoh.test/api/v1',
                validateStatus: (status) => status != null && status < 400,
              ),
            )
            ..httpClientAdapter = _StubAdapter(426, {
              'response_code': 'client_too_old',
              'response_message': 'Perbarui aplikasi kamu dulu.',
            })
            ..interceptors.add(ErrorInterceptor());

      await expectLater(
        dio.get<dynamic>('/dashboard'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<ClientTooOldFailure>(),
          ),
        ),
      );
    });
  });
}
