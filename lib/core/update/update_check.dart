import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_version.dart';
import '../error/app_failure.dart';
import 'app_config_api.dart';
import 'app_release_info.dart';
import 'app_version_compare.dart';
import 'force_update_controller.dart';
import 'force_update_info.dart';

part 'update_check.g.dart';

@Riverpod(keepAlive: true)
Future<AppReleaseInfo?> updateCheck(Ref ref) async {
  try {
    final info = await ref.watch(appConfigApiProvider).fetch();
    final current = ref.watch(appVersionProvider);

    if (isOlderVersion(current, info.minVersion)) {
      ref
          .read(forceUpdateControllerProvider.notifier)
          .reportRejected(
            ForceUpdateInfo(
              message:
                  'Versi aplikasi kamu sudah terlalu lama untuk dipakai. '
                  'Perbarui dulu untuk melanjutkan.',
              minVersion: info.minVersion,
              storeUrl: info.storeUrl,
            ),
          );
    }

    return info;
  } on AppFailure catch (_) {
    return null;
  }
}

@Riverpod(keepAlive: true)
AppReleaseInfo? optionalUpdate(Ref ref) {
  if (ref.watch(updateBannerDismissedProvider)) return null;

  final info = ref.watch(updateCheckProvider).value;
  if (info == null) return null;

  return isOlderVersion(ref.watch(appVersionProvider), info.latestVersion)
      ? info
      : null;
}

@Riverpod(keepAlive: true)
class UpdateBannerDismissed extends _$UpdateBannerDismissed {
  @override
  bool build() => false;

  void dismiss() => state = true;
}
