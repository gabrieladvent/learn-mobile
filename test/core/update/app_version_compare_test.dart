import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/update/app_version_compare.dart';

void main() {
  group('isOlderVersion', () {
    test('membandingkan per bagian, bukan sebagai teks', () {
      // Perbandingan teks biasa akan bilang '1.10.0' lebih kecil dari '1.9.0'
      // karena '1' < '9'. Di situlah bug versi biasanya bersembunyi.
      expect(isOlderVersion('1.9.0', '1.10.0'), isTrue);
      expect(isOlderVersion('1.10.0', '1.9.0'), isFalse);
    });

    test('versi sama bukan versi lama', () {
      expect(isOlderVersion('1.4.2', '1.4.2'), isFalse);
    });

    test('nomor build diabaikan', () {
      // Build number berbeda antar toko untuk rilis yang sama.
      expect(isOlderVersion('1.4.2+37', '1.4.2+120'), isFalse);
      expect(isOlderVersion('1.4.2+999', '1.5.0+1'), isTrue);
    });

    test('panjang berbeda diperlakukan sebagai nol', () {
      expect(isOlderVersion('1.4', '1.4.1'), isTrue);
      expect(isOlderVersion('1.4.0', '1.4'), isFalse);
    });

    test('yang tidak bisa dibaca dianggap TIDAK lebih tua', () {
      // Gagal ke arah aman. Kalau ini melempar atau mengembalikan true,
      // satu typo di config server bisa mengunci semua siswa.
      expect(isOlderVersion(null, '1.4.0'), isFalse);
      expect(isOlderVersion('1.4.0', null), isFalse);
      expect(isOlderVersion('', '1.4.0'), isFalse);
      expect(isOlderVersion('versi-lama', '1.4.0'), isFalse);
      expect(isOlderVersion('1.4.0', 'v2'), isFalse);
      expect(isOlderVersion('1.-4.0', '1.4.0'), isFalse);
    });
  });
}
