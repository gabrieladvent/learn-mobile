import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/observability/crash_reporting.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Berkas ini ikut dikecualikan dari analisis (analysis_options.yaml) karena
// harus menyentuh `extra` yang sudah ditandai usang — lihat sentry_extra.dart.
void main() {
  // `Scope.setExtra` menggabungkan datanya ke setiap event. Kalau ada yang
  // memanggilnya dengan token atau NISN, penyaring harus tetap menangkapnya.
  test('field sensitif di extra ikut disaring', () {
    final event = scrubEvent(
      SentryEvent(
        extra: {
          'token': 'rahasia',
          'nested': {'nisn': '1234567890', 'aman': 'ya'},
          'layar': 'beranda',
        },
      ),
    )!;

    expect(event.extra!['token'], '[disaring]');
    expect((event.extra!['nested'] as Map)['nisn'], '[disaring]');
    expect((event.extra!['nested'] as Map)['aman'], 'ya');
    expect(event.extra!['layar'], 'beranda');
  });

  test('event tanpa extra tetap aman', () {
    expect(scrubEvent(SentryEvent())!.extra, isNull);
  });
}
