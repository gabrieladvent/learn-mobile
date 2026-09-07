import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/theme/app_theme.dart';
import 'package:learn_mobile/core/ui/password_field.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

void main() {
  group('PasswordField', () {
    testWidgets('menyembunyikan teks secara bawaan', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordField(
            controller: TextEditingController(text: 'rahasia'),
            label: 'Password',
          ),
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    });

    testWidgets('tombol mata membuka dan menutup lagi', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordField(
            controller: TextEditingController(text: 'rahasia'),
            label: 'Password',
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
        reason: 'Sekali ketuk harus menampilkan password.',
      );

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
        reason: 'Ketukan kedua harus menyembunyikannya lagi.',
      );
    });

    testWidgets('label tampil DI ATAS kotak, bukan di dalamnya', (tester) async {
      // Label yang mengambang di dalam kotak menyusut jadi ~12px saat diketik
      // dan berebut tempat dengan teks contoh. Di formulir ini kita butuh
      // keduanya terbaca sekaligus.
      await tester.pumpWidget(
        _wrap(
          PasswordField(
            controller: TextEditingController(),
            label: 'Password saat ini',
            hint: 'Tanggal lahirmu, contoh 2008-05-10',
          ),
        ),
      );

      expect(find.text('Password saat ini'), findsOneWidget);
      expect(find.text('Tanggal lahirmu, contoh 2008-05-10'), findsOneWidget);
    });

    testWidgets('meneruskan pesan galat dari server', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordField(
            controller: TextEditingController(),
            label: 'Password',
            errorText: 'Password saat ini tidak sesuai.',
          ),
        ),
      );

      expect(find.text('Password saat ini tidak sesuai.'), findsOneWidget);
    });
  });
}
