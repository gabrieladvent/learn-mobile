import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/config/app_version.dart';
import 'package:learn_mobile/core/network/auth_interceptor.dart';
import 'package:learn_mobile/core/network/dio_provider.dart';
import 'package:learn_mobile/core/storage/token_storage.dart';

/// Menangkap header permintaan terakhir tanpa menyentuh jaringan.
class _CapturingAdapter implements HttpClientAdapter {
  Map<String, dynamic>? lastHeaders;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastHeaders = options.headers;

    return ResponseBody.fromString(
      jsonEncode({'response_code': 'success', 'response_message': 'Berhasil'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Secure storage asli butuh Keystore/Keychain, yang tidak ada di test.
class _FakeTokens implements TokenStorage {
  _FakeTokens(this._token);

  final String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  /// Menjalankan satu permintaan lewat interceptor, mengembalikan headernya.
  Future<Map<String, dynamic>> headersFor({
    required String appVersion,
    String? token,
  }) async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://contoh.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(_FakeTokens(token), appVersion));

    await dio.get<Map<String, dynamic>>('/apa-saja');

    return adapter.lastHeaders!;
  }

  group('AuthInterceptor', () {
    // Test terpenting di berkas ini. Header inilah SATU-SATUNYA pemicu force
    // update (ADR-0013): backend membandingkannya dengan `min_version`, dan
    // kalau isinya salah, seluruh mekanisme diam tanpa ada yang menyadarinya.
    //
    // Ini bukan kemungkinan teoretis — nilainya pernah dipatok mati `1.0.0+1`
    // di `dioProvider`, yang berarti force update tidak akan pernah terpicu
    // berapa pun versi aplikasi yang sebenarnya terpasang.
    test('mengirim versi aplikasi yang diberikan, bukan nilai mati', () async {
      final headers = await headersFor(appVersion: '1.4.2+37');

      expect(headers['X-Client-Version'], '1.4.2+37');
    });

    test('versi yang berbeda ikut berubah di header', () async {
      final headers = await headersFor(appVersion: '2.0.0+1');

      expect(headers['X-Client-Version'], '2.0.0+1');
    });

    // Server memakai header ini untuk memilih tautan toko yang benar
    // (Play Store vs App Store) saat menolak versi klien.
    test('menyertakan platform klien', () async {
      final headers = await headersFor(appVersion: '1.0.0+1');

      expect(headers['X-Client-Platform'], anyOf('android', 'ios'));
    });

    test('menempelkan token sebagai Bearer kalau siswa sudah login', () async {
      final headers = await headersFor(appVersion: '1.0.0+1', token: 'abc123');

      expect(headers['Authorization'], 'Bearer abc123');
    });

    // Tanpa ini, permintaan tanpa token akan mengirim `Bearer null` — yang
    // dibalas 401 dengan pesan membingungkan, bukan diperlakukan sebagai tamu.
    test('tanpa token, tidak ada header Authorization sama sekali', () async {
      final headers = await headersFor(appVersion: '1.0.0+1');

      expect(headers.containsKey('Authorization'), isFalse);
    });

    // Identitas klien tidak boleh bergantung pada status login: `/app-config`
    // dipanggil sebelum siswa sempat login, dan justru di situlah versi dan
    // platformnya dibutuhkan.
    test('versi tetap dikirim walau belum login', () async {
      final headers = await headersFor(appVersion: '1.4.2+37');

      expect(headers['X-Client-Version'], '1.4.2+37');
      expect(headers['X-Client-Platform'], isNotNull);
    });
  });

  // Test di atas membuktikan interceptor meneruskan versi yang DIBERIKAN
  // padanya. Tapi bug aslinya tidak di sana: `dioProvider` yang memberi nilai
  // mati `'1.0.0+1'`, dan interceptor dengan patuh mengirimkannya.
  //
  // Jadi rantainya harus diuji sampai ujung: versi yang di-override di
  // `ProviderScope` (di aplikasi asli datang dari `package_info_plus`) harus
  // sampai ke header. Ini titik tempat bug itu akan tertangkap kalau terulang.
  group('dioProvider', () {
    test('mengirim versi dari appVersionProvider, bukan nilai mati', () async {
      final adapter = _CapturingAdapter();
      final container = ProviderContainer(
        overrides: [
          appVersionProvider.overrideWithValue('3.1.4+59'),
          tokenStorageProvider.overrideWithValue(_FakeTokens(null)),
        ],
      );
      addTearDown(container.dispose);

      final dio = container.read(dioProvider)..httpClientAdapter = adapter;

      await dio.get<Map<String, dynamic>>('/apa-saja');

      expect(adapter.lastHeaders!['X-Client-Version'], '3.1.4+59');
    });
  });
}
