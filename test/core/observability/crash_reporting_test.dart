import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/observability/crash_reporting.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Test ini menjaga janji privasi di [docs/08](../../../docs/08-security-and-privacy.md).
///
/// Kegagalan di sini bukan "tampilan bergeser" — artinya token atau NISN siswa
/// terkirim ke server pihak ketiga. ADR-0014 menaruh pemetaan semacam ini di
/// kategori wajib diuji menyeluruh.
void main() {
  SentryEvent eventWithRequest({
    required String url,
    Map<String, String> headers = const {},
    Object? data,
    String? queryString,
  }) {
    return SentryEvent(
      request: SentryRequest(
        url: url,
        method: 'POST',
        headers: headers,
        data: data,
        queryString: queryString,
      ),
    );
  }

  group('header', () {
    test('Authorization dan Cookie tidak pernah ikut terkirim', () {
      final event = scrubEvent(
        eventWithRequest(
          url: 'https://lms.test/api/v1/courses',
          headers: {
            'Authorization': 'Bearer rahasia-sekali',
            'Cookie': 'session=abc',
            'X-Client-Version': '1.0.0+1',
          },
        ),
      )!;

      expect(event.request!.headers.containsKey('Authorization'), isFalse);
      expect(event.request!.headers.containsKey('Cookie'), isFalse);
      // Yang tidak sensitif tetap ada — laporan tanpa konteks tidak berguna.
      expect(event.request!.headers['X-Client-Version'], '1.0.0+1');
    });

    test('nama header dicocokkan tanpa peduli huruf besar-kecil', () {
      final event = scrubEvent(
        eventWithRequest(
          url: 'https://lms.test/api/v1/courses',
          headers: {'authorization': 'Bearer x', 'COOKIE': 'y'},
        ),
      )!;

      expect(event.request!.headers, isEmpty);
    });
  });

  group('body', () {
    test('body endpoint auth tidak dikirim sama sekali', () {
      final event = scrubEvent(
        eventWithRequest(
          url: 'https://lms.test/api/v1/auth/login',
          data: {'nisn': '1234567890', 'password': 'rahasia'},
          queryString: 'nisn=1234567890',
        ),
      )!;

      expect(event.request!.data, isNull);
      // Query string ikut hilang: `?nisn=` adalah kebocoran yang tidak terlihat
      // seperti kebocoran.
      expect(event.request!.queryString, isNull);
    });

    test('body endpoint ujian tidak dikirim — itu jawaban siswa', () {
      final event = scrubEvent(
        eventWithRequest(
          url: 'https://lms.test/api/v1/exam/12/answers',
          data: {
            'answers': ['A', 'C', 'B'],
          },
        ),
      )!;

      expect(event.request!.data, isNull);
    });

    test('endpoint biasa tetap mengirim body, tapi disaring per field', () {
      final event = scrubEvent(
        eventWithRequest(
          url: 'https://lms.test/api/v1/profile',
          data: {'full_name': 'Siswa Uji', 'nisn': '1234567890'},
        ),
      )!;

      // `SentryRequest.data` mengembalikan tampilan tak-bisa-diubah, jadi
      // tipenya `Map` polos — bukan `Map<String, dynamic>`.
      final data = event.request!.data as Map;

      expect(data['full_name'], 'Siswa Uji');
      expect(data['nisn'], '[disaring]');
    });
  });

  group('field sensitif', () {
    test('tersaring walau bersarang dalam di map dan list', () {
      final event = scrubEvent(
        eventWithRequest(
          url: 'https://lms.test/api/v1/profile',
          data: {
            'items': [
              {
                'meta': {'token': 'rahasia', 'judul': 'aman'},
              },
            ],
          },
        ),
      )!;

      final items = (event.request!.data as Map)['items'] as List;
      final meta = (items.first as Map)['meta'] as Map;

      expect(meta['token'], '[disaring]');
      expect(meta['judul'], 'aman');
    });

    test('ejaan berbeda tetap tertangkap', () {
      final event = scrubEvent(
        eventWithRequest(
          url: 'https://lms.test/api/v1/profile',
          data: {
            'password_confirmation': 'a',
            'passwordConfirmation': 'b',
            'new-password': 'c',
            'NISN': 'd',
          },
        ),
      )!;

      final data = event.request!.data as Map;

      expect(data.values, everyElement('[disaring]'));
    });

    test('payload yang sangat dalam tidak membuat penyaringnya berputar', () {
      Object nested = 'dasar';
      for (var i = 0; i < 40; i++) {
        nested = {'lapis': nested};
      }

      final event = scrubEvent(
        eventWithRequest(url: 'https://lms.test/api/v1/x', data: nested),
      );

      expect(event, isNotNull);
    });
  });

  group('identitas siswa', () {
    // Aturan docs/08: ID pengguna memakai UUID siswa, BUKAN NISN atau nama.
    test('hanya id yang bertahan; nama, email, dan IP dibuang', () {
      final event = scrubEvent(
        SentryEvent(
          user: SentryUser(
            id: 'c0ffee00-uuid',
            username: '1234567890',
            email: 'siswa@sekolah.test',
            name: 'Siswa Uji',
            ipAddress: '10.0.0.5',
            data: {'nisn': '1234567890'},
          ),
        ),
      )!;

      expect(event.user!.id, 'c0ffee00-uuid');
      expect(event.user!.username, isNull);
      expect(event.user!.email, isNull);
      expect(event.user!.name, isNull);
      expect(event.user!.ipAddress, isNull);
      expect(event.user!.data, isNull);
    });
  });

  group('breadcrumb', () {
    test('data breadcrumb ikut disaring', () {
      final crumb = scrubBreadcrumb(
        Breadcrumb(
          message: 'POST /auth/login',
          data: {'token': 'rahasia', 'status_code': 200},
        ),
      )!;

      expect(crumb.data!['token'], '[disaring]');
      expect(crumb.data!['status_code'], 200);
    });

    test('breadcrumb di dalam event ikut disaring', () {
      final event = scrubEvent(
        SentryEvent(
          breadcrumbs: [
            Breadcrumb(message: 'x', data: {'password': 'rahasia'}),
          ],
        ),
      )!;

      expect(event.breadcrumbs!.single.data!['password'], '[disaring]');
    });
  });

  group('tag', () {
    test('tag berkunci sensitif dibuang seluruhnya', () {
      final event = scrubEvent(
        SentryEvent(tags: {'nisn': '1234567890', 'flavor': 'dev'}),
      )!;

      expect(event.tags!.containsKey('nisn'), isFalse);
      expect(event.tags!['flavor'], 'dev');
    });
  });

  group('isSensitiveEndpoint', () {
    test('mengenali auth dan ujian apa pun host-nya', () {
      expect(isSensitiveEndpoint('https://lms.test/api/v1/auth/login'), isTrue);
      expect(isSensitiveEndpoint('http://10.0.2.2:8000/api/v1/exam/1'), isTrue);
      expect(isSensitiveEndpoint('/api/v1/ujian/1/jawaban'), isTrue);
    });

    test('endpoint biasa tidak ikut terblokir', () {
      expect(isSensitiveEndpoint('https://lms.test/api/v1/courses'), isFalse);
      expect(
        isSensitiveEndpoint('https://lms.test/api/v1/app-config'),
        isFalse,
      );
    });
  });

  group('setCrashReportUser', () {
    Scope emptyScope() =>
        Scope(SentryOptions(dsn: 'https://contoh@sentry.test/1'));

    test('menandai laporan dengan UUID siswa, tanpa data lain', () async {
      final scope = emptyScope();

      await setCrashReportUser(
        'c0ffee00-uuid',
        configureScope: (callback) async => callback(scope),
      );

      expect(scope.user!.id, 'c0ffee00-uuid');
      // Yang lain harus kosong sejak awal — penyaring event adalah lapis kedua,
      // bukan alasan untuk ceroboh di lapis pertama.
      expect(scope.user!.username, isNull);
      expect(scope.user!.name, isNull);
      expect(scope.user!.email, isNull);
    });

    test('logout menghapus penandanya', () async {
      final scope = emptyScope();

      await setCrashReportUser(
        'c0ffee00-uuid',
        configureScope: (callback) async => callback(scope),
      );
      await setCrashReportUser(
        null,
        configureScope: (callback) async => callback(scope),
      );

      expect(scope.user, isNull);
    });
  });

  // Crash tetap harus sampai. Yang dibuang isinya, bukan laporannya — kalau
  // penyaring ini mengembalikan null, kita kehilangan justru bug yang perlu
  // diperbaiki.
  test('event tidak pernah dibuang seluruhnya', () {
    expect(scrubEvent(SentryEvent()), isNotNull);
    expect(
      scrubEvent(eventWithRequest(url: 'https://lms.test/api/v1/auth/login')),
      isNotNull,
    );
  });
}
