import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

/// Mencatat setiap perubahan state provider.
///
/// KENAPA INI WAJIB (ADR-0005): BLoC mencatat riwayat perubahan secara bawaan
/// karena setiap perubahan di sana punya nama event. Riverpod tidak — perubahan
/// terjadi lewat pemanggilan method biasa. Observer inilah yang menutup
/// kekurangan itu.
///
/// Yang mau dijawab kelak: "jawaban ujian saya hilang". Tanpa jejak seperti ini,
/// tidak ada cara menelusurinya selain menebak.
///
/// ```
/// answer(q3) → saving → saved 14:02:11
/// connection lost → queued(q4) → submit failed (timeout)
/// ```
///
/// Nanti saat Sentry dipasang (Fase 5), kirim jejak ini sebagai breadcrumb.
/// Untuk sekarang cukup ke log lokal.
final class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  /// Hanya provider yang benar-benar penting yang dicatat. Mencatat SEMUA
  /// provider akan menenggelamkan jejak ujian di antara ribuan baris rebuild
  /// UI biasa — dan justru bikin log tidak terpakai.
  static const _watched = ['exam', 'answer', 'outbox', 'submission', 'auth'];

  bool _isWatched(String name) {
    final lower = name.toLowerCase();
    return _watched.any(lower.contains);
  }

  String _nameOf(ProviderObserverContext context) =>
      context.provider.name ?? context.provider.runtimeType.toString();

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    final name = _nameOf(context);
    if (!_isWatched(name)) return;

    developer.log('$name → $newValue', name: 'state');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    // Kegagalan SELALU dicatat, apa pun providernya — ini yang paling dicari
    // saat menyelidiki laporan siswa.
    developer.log(
      '${_nameOf(context)} GAGAL: $error',
      name: 'state',
      error: error,
      // Stack trace hanya di non-produksi supaya log rilis tidak membengkak.
      stackTrace: AppConfig.current.isProduction ? null : stackTrace,
    );
  }
}
