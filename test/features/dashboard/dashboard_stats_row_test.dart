import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/theme/app_theme.dart';
import 'package:learn_mobile/features/dashboard/domain/dashboard.dart';
import 'package:learn_mobile/features/dashboard/presentation/widgets/dashboard_stats_row.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester, {
    required double textScale,
    Size size = const Size(1080, 2400),
    double pixelRatio = 2.625,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: DashboardStatsRow(
                stats: DashboardStats(
                  assignmentsPending: 3,
                  assignmentsCompleted: 12,
                  examsCompleted: 6,
                  avgScore: 82.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // Kartu statistik pernah meluber 3,4px di lebar HP. Tidak terlihat di layar
  // sungguhan karena fontnya lebih ramping dari font uji — tapi siswa yang
  // membesarkan ukuran teks di setelan HP akan menabraknya betulan.
  //
  // Test ini tidak memakai `expect`: framework test Flutter menggagalkan test
  // secara otomatis begitu ada exception rendering, dan luber adalah salah
  // satunya.
  for (final scale in [1.0, 1.3, 1.6, 2.0]) {
    testWidgets('tidak meluber pada skala teks $scale', (tester) async {
      await pumpAt(tester, textScale: scale);
    });
  }

  testWidgets('tidak meluber di HP sempit (320dp)', (tester) async {
    await pumpAt(
      tester,
      textScale: 1.3,
      size: const Size(640, 1280),
      pixelRatio: 2,
    );
  });

  testWidgets('kartu jadi lebih tinggi saat teks diperbesar', (tester) async {
    await pumpAt(tester, textScale: 1.0);
    final normal = tester.getRect(find.byType(GridView)).height;

    await pumpAt(tester, textScale: 1.6);
    final besar = tester.getRect(find.byType(GridView)).height;

    expect(besar, greaterThan(normal));
  });
}
