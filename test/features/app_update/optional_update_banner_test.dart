import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/config/app_version.dart';
import 'package:learn_mobile/core/update/app_config_api.dart';
import 'package:learn_mobile/core/update/app_release_info.dart';
import 'package:learn_mobile/core/ui/glass_surface.dart';
import 'package:learn_mobile/core/update/update_check.dart';
import 'package:learn_mobile/features/app_update/presentation/optional_update_banner.dart';

class _FakeApi implements AppConfigApi {
  _FakeApi(this._info);

  final AppReleaseInfo _info;

  @override
  Future<AppReleaseInfo> fetch() async => _info;
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required AppReleaseInfo info,
  String version = '1.4.0',
}) async {
  final container = ProviderContainer(
    overrides: [
      appVersionProvider.overrideWithValue(version),
      appConfigApiProvider.overrideWithValue(_FakeApi(info)),
    ],
  );
  addTearDown(container.dispose);

  await container.read(updateCheckProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: OptionalUpdateBanner())),
    ),
  );

  return container;
}

void main() {
  group('OptionalUpdateBanner', () {
    testWidgets('muncul saat ada versi lebih baru', (tester) async {
      await _pump(
        tester,
        info: const AppReleaseInfo(
          latestVersion: '1.6.0',
          storeUrl: 'https://toko.test/app',
        ),
      );

      expect(find.text('Versi 1.6.0 sudah tersedia'), findsOne);
      expect(find.text('Perbarui'), findsOne);
    });

    testWidgets('hilang setelah ditutup', (tester) async {
      await _pump(tester, info: const AppReleaseInfo(latestVersion: '1.6.0'));

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(find.text('Versi 1.6.0 sudah tersedia'), findsNothing);
    });

    testWidgets('tidak memakan ruang saat versi sudah terbaru', (tester) async {
      await _pump(tester, info: const AppReleaseInfo(latestVersion: '1.4.0'));

      expect(find.byType(SoftCard), findsNothing);
    });
  });
}
