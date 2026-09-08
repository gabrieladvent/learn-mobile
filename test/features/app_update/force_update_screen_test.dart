import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/update/force_update_controller.dart';
import 'package:learn_mobile/core/update/force_update_info.dart';
import 'package:learn_mobile/features/app_update/presentation/force_update_screen.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  ForceUpdateInfo? info,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  if (info != null) {
    container.read(forceUpdateControllerProvider.notifier).reportRejected(info);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ForceUpdateScreen()),
    ),
  );

  return container;
}

void main() {
  group('ForceUpdateScreen', () {
    testWidgets('menampilkan pesan dan versi minimum dari server', (
      tester,
    ) async {
      await _pump(
        tester,
        info: const ForceUpdateInfo(
          message: 'Versi aplikasi kamu sudah terlalu lama.',
          minVersion: '1.4.0',
          storeUrl: 'https://play.google.com/store/apps/details?id=x',
        ),
      );

      expect(find.text('Versi aplikasi kamu sudah terlalu lama.'), findsOne);
      expect(find.text('Versi minimum: 1.4.0'), findsOne);
      expect(find.text('Perbarui sekarang'), findsOne);
    });

    testWidgets('tanpa store_url, tombol diganti petunjuk manual', (
      tester,
    ) async {
      // Tombol yang tidak bisa berbuat apa-apa lebih buruk daripada kalimat
      // yang memberi tahu harus ke mana.
      await _pump(tester, info: const ForceUpdateInfo(message: 'Perbarui.'));

      expect(find.text('Perbarui sekarang'), findsNothing);
      expect(find.textContaining('Play Store'), findsOne);
    });

    testWidgets('tetap terbaca walau state kosong', (tester) async {
      // Bisa terjadi kalau layar ini terbuka lewat deep link, bukan lewat
      // penolakan 426. Tidak boleh menampilkan layar kosong.
      await _pump(tester);

      expect(find.text('Perbarui aplikasi dulu'), findsOne);
      expect(find.textContaining('terlalu lama'), findsOne);
    });

    testWidgets('tidak bisa ditutup dengan tombol back', (tester) async {
      await _pump(tester, info: const ForceUpdateInfo(message: 'Perbarui.'));

      // `PopScope` generiknya tidak eksplisit di layar ini, jadi dicari lewat
      // predikat — bukan `byType` yang butuh tipe persis.
      expect(
        find.byWidgetPredicate(
          (widget) => widget is PopScope && !widget.canPop,
        ),
        findsOne,
      );
    });
  });
}
