import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/observability/app_provider_observer.dart';

void main() {
  runApp(
    // `ProviderScope` menyimpan state semua provider. Wajib membungkus seluruh
    // aplikasi — tanpa ini, `ref.watch` di mana pun akan gagal.
    const ProviderScope(
      observers: [AppProviderObserver()],
      child: LearnApp(),
    ),
  );
}
