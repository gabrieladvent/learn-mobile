@Tags(['preview'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/theme/app_theme.dart';
import 'package:learn_mobile/core/ui/app_toast.dart';
import 'package:learn_mobile/features/auth/application/auth_controller.dart';
import 'package:learn_mobile/features/auth/domain/auth_session.dart';
import 'package:learn_mobile/features/auth/domain/student.dart';
import 'package:learn_mobile/features/auth/presentation/login_screen.dart';
import 'package:learn_mobile/core/storage/app_preferences.dart';
import 'package:learn_mobile/features/dashboard/presentation/home_screen.dart';
import 'package:learn_mobile/features/onboarding/presentation/intro_screen.dart';

class _FakePreferences implements AppPreferences {
  @override
  Future<bool> hasSeenIntro() async => false;

  @override
  Future<void> markIntroSeen() async {}
}

class _FakeAuth extends AuthController {
  _FakeAuth(this._session);

  final AuthSession? _session;

  @override
  Future<AuthSession?> build() async => _session;
}

/// Font bawaan Flutter ada di dalam instalasi Flutter, yang letaknya berbeda di
/// tiap komputer. `flutter test` selalu menyetel `FLUTTER_ROOT`, jadi itu yang
/// dipakai — bukan path laptop siapa pun.
String get _fontDir {
  final root = Platform.environment['FLUTTER_ROOT'];

  if (root == null || root.isEmpty) {
    throw StateError(
      'FLUTTER_ROOT tidak ada. Jalankan lewat `flutter test`, bukan '
      '`dart test`.',
    );
  }

  return '$root/bin/cache/artifacts/material_fonts';
}

Future<void> loadRoboto() async {
  for (final entry in {
    'Roboto': ['Roboto-Regular.ttf', 'Roboto-Bold.ttf'],
    'MaterialIcons': ['MaterialIcons-Regular.otf'],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      loader.addFont(
        File('$_fontDir/$file').readAsBytes().then(
              (bytes) => bytes.buffer.asByteData(),
            ),
      );
    }
    await loader.load();
  }
}

void main() {
  setUpAll(loadRoboto);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget home, {
    ThemeData? theme,
    AuthSession? session,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2100)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuth(session)),
          appPreferencesProvider.overrideWithValue(_FakePreferences()),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          // Gambar harus sama persis tiap kali dijalankan — jadi geraknya
          // dimatikan dan semua animasi berhenti di keadaan akhirnya.
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: home,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/$name.png'),
    );
  }

  testWidgets('login terang', (tester) async {
    await shoot(tester, 'login_light', const LoginScreen());
  });

  testWidgets('login gelap', (tester) async {
    await shoot(tester, 'login_dark', const LoginScreen(), theme: AppTheme.dark);
  });

  testWidgets('tiga jenis pesan sekilas', (tester) async {
    late AppToast toast;

    tester.view
      ..physicalSize = const Size(1080, 900)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            toast = AppToast.of(context);
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    toast.showFailure('Tidak ada koneksi internet.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/toast_error.png'),
    );

    toast.showSuccess('Password berhasil diganti.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/toast_success.png'),
    );

    toast.showInfo('Ada materi baru di Matematika.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/toast_info.png'),
    );
  });

  testWidgets('onboarding terang', (tester) async {
    await shoot(tester, 'intro_light', const IntroScreen());
  });

  testWidgets('onboarding gelap', (tester) async {
    await shoot(tester, 'intro_dark', const IntroScreen(), theme: AppTheme.dark);
  });

  testWidgets('beranda terang', (tester) async {
    await shoot(
      tester,
      'home_light',
      const HomeScreen(),
      session: const AuthSession(
        token: 'token',
        student: Student(
          id: 'id',
          fullName: 'Budi Santoso',
          nisn: '0012345001',
          className: 'X IPA 1',
        ),
        mustChangePassword: false,
      ),
    );
  });
}
