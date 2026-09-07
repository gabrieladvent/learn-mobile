import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/theme/app_theme.dart';
import 'package:learn_mobile/core/ui/app_snack_bar.dart';

void main() {
  Future<ScaffoldMessengerState> pumpHost(WidgetTester tester) async {
    late ScaffoldMessengerState messenger;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            messenger = ScaffoldMessenger.of(context);
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    return messenger;
  }

  group('AppSnackBar', () {
    testWidgets('showSuccess menampilkan pesan dengan ikon centang', (tester) async {
      final messenger = await pumpHost(tester);

      messenger.showSuccess('Password berhasil diganti.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Password berhasil diganti.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('showFailure memakai ikon galat', (tester) async {
      final messenger = await pumpHost(tester);

      messenger.showFailure('Tidak ada koneksi internet.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('pesan baru menggantikan yang lama, tidak mengantre', (tester) async {
      // Tanpa hideCurrentSnackBar(), SnackBar mengantre — pesan terbaru baru
      // muncul setelah yang lama habis waktunya, dan siswa membaca kabar basi.
      final messenger = await pumpHost(tester);

      messenger.showSuccess('Pesan pertama');
      await tester.pump();
      messenger.showFailure('Pesan kedua');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Pesan pertama'), findsNothing);
      expect(find.text('Pesan kedua'), findsOneWidget);
    });
  });
}
