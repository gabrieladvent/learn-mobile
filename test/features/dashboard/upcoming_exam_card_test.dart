import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/features/dashboard/presentation/widgets/upcoming_exam_card.dart';

void main() {
  group('formatExamSchedule', () {
    // Waktu diubah ke zona perangkat lebih dulu, jadi test menyusun waktunya
    // sebagai waktu lokal — kalau tidak, hasilnya berbeda di tiap mesin.
    test('menyusun hari, tanggal, bulan, dan jam dalam bahasa Indonesia', () {
      // 8 September 2026 adalah hari Selasa.
      expect(formatExamSchedule(DateTime(2026, 9, 8, 7)), 'Sel, 8 Sep 7.00');
    });

    test('menit satu digit tetap dua digit', () {
      expect(
        formatExamSchedule(DateTime(2026, 9, 8, 13, 5)),
        'Sel, 8 Sep 13.05',
      );
    });

    test('waktu UTC ditampilkan dalam zona perangkat', () {
      final utc = DateTime.utc(2026, 9, 8, 7);

      expect(formatExamSchedule(utc), formatExamSchedule(utc.toLocal()));
    });
  });
}
