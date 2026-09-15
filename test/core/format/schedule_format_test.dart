import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/format/schedule_format.dart';

void main() {
  // 14 September 2026, hari Senin, pukul 08.00 waktu perangkat.
  final now = DateTime(2026, 9, 14, 8);

  group('formatSchedule', () {
    test('hari ini, besok, dan kemarin disebut dengan kata', () {
      expect(
        formatSchedule(DateTime(2026, 9, 14, 23, 59), now: now),
        'hari ini 23.59',
      );
      expect(formatSchedule(DateTime(2026, 9, 15, 7), now: now), 'besok 07.00');
      expect(
        formatSchedule(DateTime(2026, 9, 13, 23, 59), now: now),
        'kemarin 23.59',
      );
    });

    // "Besok" dihitung dari tanggal kalender, bukan selisih 24 jam. Tugas
    // pukul 00.30 yang dilihat pukul 23.00 tetap "besok", walau tinggal 90
    // menit — begitulah siswa membacanya.
    test('pergantian hari mengikuti kalender, bukan 24 jam', () {
      expect(
        formatSchedule(
          DateTime(2026, 9, 15, 0, 30),
          now: DateTime(2026, 9, 14, 23),
        ),
        'besok 00.30',
      );
    });

    test('tanggal lain memakai nama hari dan bulan', () {
      expect(
        formatSchedule(DateTime(2026, 9, 22, 7), now: now),
        'Sel, 22 Sep 07.00',
      );
    });

    test('tahun hanya ditulis kalau berbeda', () {
      expect(
        formatSchedule(DateTime(2027, 1, 4, 7), now: now),
        'Sen, 4 Jan 2027 07.00',
      );
    });

    test('waktu UTC ditampilkan dalam zona perangkat', () {
      final utc = DateTime.utc(2026, 9, 20, 7);

      expect(
        formatSchedule(utc, now: now),
        formatSchedule(utc.toLocal(), now: now),
      );
    });
  });
}
