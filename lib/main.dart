import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app/app.dart';
import 'core/config/app_version.dart';
import 'core/observability/app_provider_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final packageInfo = await PackageInfo.fromPlatform();

  runApp(
    ProviderScope(
      observers: const [AppProviderObserver()],
      overrides: [
        appVersionProvider.overrideWithValue(
          '${packageInfo.version}+${packageInfo.buildNumber}',
        ),
      ],
      child: const LearnApp(),
    ),
  );
}
