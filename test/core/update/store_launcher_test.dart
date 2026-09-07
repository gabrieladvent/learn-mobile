import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/update/store_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

/// Peluncur palsu: mencatat permintaan tanpa menyentuh plugin platform.
class _Spy {
  Uri? url;
  LaunchMode? mode;
  bool called = false;

  _Spy({this.result = true, this.throws});

  final bool result;
  final Object? throws;

  Future<bool> call(Uri url, {LaunchMode mode = LaunchMode.platformDefault}) async {
    called = true;
    this.url = url;
    this.mode = mode;

    final error = throws;
    if (error != null) throw error;

    return result;
  }
}

void main() {
  group('openStoreUrl', () {
    test('membuka tautan https di aplikasi toko, bukan WebView', () async {
      final spy = _Spy();

      final result = await openStoreUrl(
        'https://play.google.com/store/apps/details?id=id.sekolah.learn',
        launcher: spy.call,
      );

      expect(result, isTrue);
      expect(spy.url.toString(), contains('play.google.com'));
      // Pembaruan hanya bisa dilakukan di aplikasi tokonya, bukan di WebView.
      expect(spy.mode, LaunchMode.externalApplication);
    });

    test('skema toko asli tetap diterima', () async {
      for (final url in [
        'market://details?id=id.sekolah.learn',
        'itms-apps://itunes.apple.com/app/id123',
      ]) {
        expect(await openStoreUrl(url, launcher: _Spy().call), isTrue,
            reason: url);
      }
    });

    // Inilah alasan daftar skema itu ada. Tanpa penyaringan, backend yang salah
    // konfigurasi — atau dibobol — bisa menyuruh aplikasi membuka apa saja di
    // HP siswa lewat `store_url`.
    test('menolak skema di luar toko tanpa memanggil peluncur', () async {
      final spy = _Spy();

      for (final url in [
        'javascript:alert(1)',
        'file:///etc/passwd',
        'tel:+628123456789',
        'intent://scan/#Intent;scheme=zxing;end',
      ]) {
        expect(await openStoreUrl(url, launcher: spy.call), isFalse,
            reason: url);
      }

      expect(spy.called, isFalse);
    });

    // `Uri.tryParse('bukan url')` TIDAK mengembalikan null — ia menghasilkan Uri
    // sah tanpa skema. Jadi yang menyaringnya adalah daftar skema, bukan hasil
    // parse-nya.
    test('menolak tautan tanpa skema dan tautan kosong', () async {
      final spy = _Spy();

      for (final url in ['bukan url', '', 'play.google.com/store']) {
        expect(await openStoreUrl(url, launcher: spy.call), isFalse,
            reason: '"$url"');
      }

      expect(spy.called, isFalse);
    });

    // Di layar force update, exception yang lolos berarti siswa terjebak di
    // layar rusak — dan layar itu memang sudah tidak punya jalan keluar lain.
    test('kegagalan platform jadi false, bukan exception', () async {
      final spy = _Spy(throws: PlatformException(code: 'ACTIVITY_NOT_FOUND'));

      expect(
        await openStoreUrl('https://play.google.com/x', launcher: spy.call),
        isFalse,
      );
    });

    test('peluncur yang mengembalikan false diteruskan apa adanya', () async {
      final spy = _Spy(result: false);

      expect(
        await openStoreUrl('https://play.google.com/x', launcher: spy.call),
        isFalse,
      );
    });
  });
}
