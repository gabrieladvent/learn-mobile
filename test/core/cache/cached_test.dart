import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/cache/cached.dart';

void main() {
  group('formatLastUpdated', () {
    // Detik yang berjalan membuat siswa memperhatikan penandanya, padahal ia
    // justru harus tidak mencolok.
    test('di bawah satu menit dibulatkan jadi "baru saja"', () {
      expect(formatLastUpdated(const Duration(seconds: 0)), 'baru saja');
      expect(formatLastUpdated(const Duration(seconds: 59)), 'baru saja');
    });

    test('menit, jam, dan hari', () {
      expect(formatLastUpdated(const Duration(minutes: 5)), '5 menit lalu');
      expect(formatLastUpdated(const Duration(minutes: 59)), '59 menit lalu');
      expect(formatLastUpdated(const Duration(hours: 2)), '2 jam lalu');
      expect(formatLastUpdated(const Duration(hours: 23)), '23 jam lalu');
      expect(formatLastUpdated(const Duration(days: 1)), 'kemarin');
      expect(formatLastUpdated(const Duration(days: 3)), '3 hari lalu');
    });
  });

  group('Cached', () {
    test('umurnya dihitung dari waktu pengambilan', () {
      final cached = Cached<int>(
        value: 1,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        isFresh: false,
      );

      expect(cached.age.inMinutes, 10);
    });

    // Salinan yang tampil sesaat sebelum jaringan menjawab BUKAN kegagalan,
    // dan tidak perlu diberitahukan sebagai masalah.
    test('belum segar berbeda dari gagal menyegarkan', () {
      final menunggu = Cached<int>(
        value: 1,
        fetchedAt: DateTime.now(),
        isFresh: false,
      );

      expect(menunggu.isFresh, isFalse);
      expect(menunggu.refreshFailed, isFalse);
    });
  });
}
