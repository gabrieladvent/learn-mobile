import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/update/update_check.dart';
import 'router.dart';

class LearnApp extends ConsumerWidget {
  const LearnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(updateCheckProvider, (_, _) {});

    return MaterialApp.router(
      title: 'Learn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
