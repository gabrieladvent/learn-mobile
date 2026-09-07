import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/storage/app_preferences.dart';
import 'package:learn_mobile/core/theme/app_theme.dart';
import 'package:learn_mobile/features/onboarding/presentation/intro_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferences extends Mock implements AppPreferences {}

void main() {
  late _MockPreferences prefs;

  setUp(() {
    prefs = _MockPreferences();
    when(prefs.hasSeenIntro).thenAnswer((_) async => false);
    when(prefs.markIntroSeen).thenAnswer((_) async {});
  });

  Future<void> pumpIntro(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Penyimpanan asli menyentuh platform channel yang tidak ada di test.
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(theme: AppTheme.light, home: const IntroScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('IntroScreen', () {
    testWidgets('tombolnya "Lanjut" sampai halaman terakhir', (tester) async {
      await pumpIntro(tester);

      expect(find.text('Lanjut'), findsOneWidget);
      expect(find.text('Mulai'), findsNothing);

      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Lanjut'), findsOneWidget);

      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(
        find.text('Mulai'),
        findsOneWidget,
        reason: 'Halaman terakhir harus menawarkan "Mulai", bukan "Lanjut".',
      );
    });

    testWidgets('"Mulai" menandai intro sudah dilihat', (tester) async {
      await pumpIntro(tester);

      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();

      verify(prefs.markIntroSeen).called(1);
    });

    testWidgets('"Lewati" juga menandai sudah dilihat', (tester) async {
      // Kalau Lewati tidak menyimpan penanda, intro muncul lagi setiap kali
      // aplikasi dibuka — persis yang paling menjengkelkan.
      await pumpIntro(tester);

      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();

      verify(prefs.markIntroSeen).called(1);
    });
  });
}
