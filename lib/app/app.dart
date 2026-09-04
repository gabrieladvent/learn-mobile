import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

/// Akar aplikasi.
///
/// `MaterialApp.router` (bukan `MaterialApp` biasa) supaya navigasi ditangani
/// go_router — termasuk deep link dari notifikasi nanti.
class LearnApp extends ConsumerWidget {
  const LearnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Learn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
