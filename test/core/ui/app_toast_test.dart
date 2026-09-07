import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/theme/app_semantic.dart';
import 'package:learn_mobile/core/theme/app_theme.dart';
import 'package:learn_mobile/core/ui/app_toast.dart';
import 'package:learn_mobile/core/ui/glass_surface.dart';

Future<AppToast> pumpHost(WidgetTester tester, {ThemeData? theme}) async {
  late AppToast toast;

  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Builder(
        builder: (context) {
          toast = AppToast.of(context);
          return const Scaffold(body: SizedBox());
        },
      ),
    ),
  );

  return toast;
}

/// Warna dasar kaca pesan yang sedang tampil, dikembalikan ke keadaan pekat.
///
/// Isian kaca selalu tembus pandang, jadi yang dibandingkan adalah warna
/// dasarnya — bukan hasil akhirnya yang tercampur latar.
Color opaqueBackground(WidgetTester tester) {
  final decorated = tester.widget<DecoratedBox>(
    find
        .descendant(of: find.byType(GlassPanel), matching: find.byType(DecoratedBox))
        .first,
  );

  return (decorated.decoration as BoxDecoration).color!.withValues(alpha: 1);
}

/// Warna garis tepi — inilah yang membedakan berhasil dari info.
Color borderColor(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(of: find.byType(GlassPanel), matching: find.byType(Container))
        .first,
  );

  return ((container.decoration! as BoxDecoration).border! as Border).top.color
      .withValues(alpha: 1);
}

void main() {
  group('AppToast', () {
    testWidgets('showSuccess menampilkan pesan dengan ikon centang', (
      tester,
    ) async {
      final toast = await pumpHost(tester);

      toast.showSuccess('Password berhasil diganti.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Password berhasil diganti.'), findsOne);
      expect(find.byIcon(Icons.check_circle_rounded), findsOne);
    });

    testWidgets('showFailure memakai ikon galat', (tester) async {
      final toast = await pumpHost(tester);

      toast.showFailure('Tidak ada koneksi internet.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.error_rounded), findsOne);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets('muncul di paruh ATAS layar', (tester) async {
      // Alasan pindah dari bawah: di layar login dan ganti password, tombol
      // utamanya ada di bawah — pesan yang muncul di sana menutupi tombol yang
      // baru saja ditekan siswa.
      final toast = await pumpHost(tester);

      toast.showSuccess('Berhasil.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final screen = tester.getSize(find.byType(MaterialApp));
      final message = tester.getCenter(find.text('Berhasil.'));

      expect(message.dy, lessThan(screen.height / 2));
    });

    testWidgets('info punya ikon dan warna sendiri', (tester) async {
      final toast = await pumpHost(tester);

      toast.showInfo('Materi baru ditambahkan.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.info_rounded), findsOne);
      expect(borderColor(tester), AppSemantic.info(Brightness.light));
    });

    testWidgets('berhasil: latar netral, garis tepi hijau', (tester) async {
      // Bidang berwarna disimpan untuk kegagalan saja. Kabar baik tidak perlu
      // merebut perhatian sekuat kabar buruk.
      final toast = await pumpHost(tester);

      toast.showSuccess('Berhasil.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(opaqueBackground(tester), const Color(0xFFFFFFFF));
      expect(borderColor(tester), AppSemantic.success(Brightness.light));
    });

    testWidgets('mode gelap: latar netralnya ikut gelap', (tester) async {
      final toast = await pumpHost(tester, theme: AppTheme.dark);

      toast.showSuccess('Berhasil.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(opaqueBackground(tester), AppTheme.dark.colorScheme.surfaceBright);
      expect(borderColor(tester), AppSemantic.success(Brightness.dark));
    });

    testWidgets('galat memakai bidang merah lembut di kedua mode', (
      tester,
    ) async {
      // Satu-satunya pesan yang boleh memakai bidang berwarna: merahnya membuat
      // siswa tahu ada yang salah sebelum sempat membaca kalimatnya.
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final toast = await pumpHost(tester, theme: theme);

        toast.showFailure('Gagal.');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(opaqueBackground(tester), theme.colorScheme.errorContainer);
      }
    });

    testWidgets('pesan baru menggantikan yang lama, tidak mengantre', (
      tester,
    ) async {
      // Tanpa penggantian, pesan terbaru baru muncul setelah yang lama habis
      // waktunya — dan siswa membaca kabar basi.
      final toast = await pumpHost(tester);

      toast.showSuccess('Pesan pertama');
      await tester.pump();
      toast.showFailure('Pesan kedua');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Pesan pertama'), findsNothing);
      expect(find.text('Pesan kedua'), findsOne);
    });

    testWidgets('menghilang sendiri setelah beberapa detik', (tester) async {
      final toast = await pumpHost(tester);

      toast.showSuccess('Berhasil.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Berhasil.'), findsOne);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Berhasil.'), findsNothing);
    });

    testWidgets('diketuk langsung hilang, tanpa menunggu', (tester) async {
      final toast = await pumpHost(tester);

      toast.showSuccess('Berhasil.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Berhasil.'));
      await tester.pumpAndSettle();

      expect(find.text('Berhasil.'), findsNothing);
    });
  });
}
