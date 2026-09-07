import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/config/app_version.dart';
import 'package:learn_mobile/core/error/app_failure.dart';
import 'package:learn_mobile/core/update/app_config_api.dart';
import 'package:learn_mobile/core/update/app_release_info.dart';
import 'package:learn_mobile/core/update/force_update_controller.dart';
import 'package:learn_mobile/core/update/update_check.dart';

/// API tiruan: tidak menyentuh jaringan sama sekali.
class _FakeApi implements AppConfigApi {
  _FakeApi.returns(this._info) : _failure = null;
  _FakeApi.fails(this._failure) : _info = null;

  final AppReleaseInfo? _info;
  final AppFailure? _failure;

  @override
  Future<AppReleaseInfo> fetch() async {
    final failure = _failure;
    if (failure != null) throw failure;

    return _info!;
  }
}

ProviderContainer _containerWith(AppConfigApi api, {String version = '1.4.0'}) {
  final container = ProviderContainer(
    overrides: [
      appVersionProvider.overrideWithValue(version),
      appConfigApiProvider.overrideWithValue(api),
    ],
  );
  addTearDown(container.dispose);

  return container;
}

void main() {
  group('updateCheck', () {
    test('versi di bawah minimum mengunci aplikasi sejak cold start', () async {
      // Nilai tambah dibanding menunggu 426: siswa tahu sebelum sempat login.
      final container = _containerWith(
        _FakeApi.returns(
          const AppReleaseInfo(
            minVersion: '1.5.0',
            latestVersion: '1.6.0',
            storeUrl: 'https://toko.test/app',
          ),
        ),
      );

      await container.read(updateCheckProvider.future);

      final lock = container.read(forceUpdateControllerProvider);
      expect(lock, isNotNull);
      expect(lock!.minVersion, '1.5.0');
      expect(lock.storeUrl, 'https://toko.test/app');
    });

    test('versi masih cukup tapi ketinggalan → banner, bukan kunci', () async {
      final container = _containerWith(
        _FakeApi.returns(
          const AppReleaseInfo(minVersion: '1.3.0', latestVersion: '1.6.0'),
        ),
      );

      await container.read(updateCheckProvider.future);

      expect(container.read(forceUpdateControllerProvider), isNull);
      expect(container.read(optionalUpdateProvider)?.latestVersion, '1.6.0');
    });

    test('sudah versi terbaru → tidak ada banner', () async {
      final container = _containerWith(
        _FakeApi.returns(
          const AppReleaseInfo(minVersion: '1.3.0', latestVersion: '1.4.0'),
        ),
      );

      await container.read(updateCheckProvider.future);

      expect(container.read(optionalUpdateProvider), isNull);
    });

    test('banner yang ditutup tidak muncul lagi', () async {
      final container = _containerWith(
        _FakeApi.returns(const AppReleaseInfo(latestVersion: '1.6.0')),
      );

      await container.read(updateCheckProvider.future);
      expect(container.read(optionalUpdateProvider), isNotNull);

      container.read(updateBannerDismissedProvider.notifier).dismiss();

      expect(container.read(optionalUpdateProvider), isNull);
    });

    test('endpoint belum ada → aplikasi jalan normal', () async {
      // Ini keadaan HARI INI: backend belum punya /app-config.
      final container = _containerWith(_FakeApi.fails(const NotFoundFailure()));

      expect(await container.read(updateCheckProvider.future), isNull);
      expect(container.read(forceUpdateControllerProvider), isNull);
      expect(container.read(optionalUpdateProvider), isNull);
    });

    test('offline saat dibuka → tidak mengunci apa pun', () async {
      final container = _containerWith(_FakeApi.fails(const NetworkFailure()));

      expect(await container.read(updateCheckProvider.future), isNull);
      expect(container.read(forceUpdateControllerProvider), isNull);
    });

    test('payload tanpa min_version tidak mengunci', () async {
      // Field yang hilang berarti "tidak ada batasan", bukan "kunci".
      final container = _containerWith(
        _FakeApi.returns(const AppReleaseInfo()),
      );

      await container.read(updateCheckProvider.future);

      expect(container.read(forceUpdateControllerProvider), isNull);
    });
  });
}
