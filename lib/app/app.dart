import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/observability/crash_reporting.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_scroll_behavior.dart';
import '../core/update/update_check.dart';
import '../features/auth/application/auth_controller.dart';
import 'router.dart';

class LearnApp extends ConsumerWidget {
  const LearnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(updateCheckProvider, (_, _) {});

    ref.listen(authControllerProvider, (_, next) {
      setCrashReportUser(next.value?.student.id);
    });

    return MaterialApp.router(
      title: 'Learn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
