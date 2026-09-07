import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_semantic.dart';
import '../theme/app_spacing.dart';
import 'glass_surface.dart';

/// Pemberitahuan sekilas di **tengah atas** layar.
///
/// Menggantikan `SnackBar` bawaan, dengan dua perbedaan yang disengaja:
///
/// 1. **Muncul di atas, bukan di bawah.** Di layar yang punya tombol utama di
///    bagian bawah (login, ganti password), pesan yang muncul di bawah menutupi
///    tombol yang baru saja ditekan siswa.
/// 2. **Warnanya mengikuti tema.** `SnackBar` bawaan memakai `inverseSurface` —
///    yaitu warna yang SENGAJA terbalik dari tema: putih di mode gelap, hitam di
///    mode terang. Di sini kebalikannya: gelap ikut gelap, terang ikut terang.
///
/// Karena latarnya jadi senada dengan halaman, ia butuh garis tepi dan bayangan
/// supaya tetap terbaca sebagai lapisan terpisah — tanpa itu, kartu terang di
/// atas halaman terang akan terlihat menyatu.
///
/// Dibangun di atas [Overlay], bukan [ScaffoldMessenger], karena posisinya harus
/// bebas dari tata letak `Scaffold`. Ambil dulu sebelum `await`, seperti
/// `ScaffoldMessenger.of(context)`:
///
/// ```dart
/// final toast = AppToast.of(context);
/// await sesuatuYangLama();
/// toast.showSuccess('Berhasil.');
/// ```
enum AppToastKind { success, info, failure }

class AppToast {
  const AppToast._(this._overlay);

  final OverlayState _overlay;

  /// Berapa lama pesan bertahan sebelum menghilang sendiri.
  static const Duration _visibleFor = Duration(seconds: 3);

  /// Hanya boleh ada satu pesan di layar. Yang baru menggantikan yang lama,
  /// TIDAK mengantre di belakangnya — siswa yang menekan tombol dua kali harus
  /// membaca hasil terakhir, bukan kabar basi dari beberapa detik lalu.
  static OverlayEntry? _current;

  /// `rootOverlay` supaya pesan tetap di lapisan paling atas meski dipanggil
  /// dari dalam navigator bersarang atau dialog.
  static AppToast of(BuildContext context) =>
      AppToast._(Overlay.of(context, rootOverlay: true));

  void showSuccess(String message) => _show(message, AppToastKind.success);

  void showInfo(String message) => _show(message, AppToastKind.info);

  void showFailure(String message) => _show(message, AppToastKind.failure);

  void _show(String message, AppToastKind kind) {
    dismissCurrent();

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastCard(
        message: message,
        kind: kind,
        visibleFor: _visibleFor,
        onDismissed: () {
          if (_current == entry) _current = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );

    _current = entry;
    _overlay.insert(entry);
  }

  /// Menutup pesan yang sedang tampil, kalau ada.
  static void dismissCurrent() {
    final entry = _current;
    _current = null;

    if (entry != null && entry.mounted) entry.remove();
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    required this.message,
    required this.kind,
    required this.visibleFor,
    required this.onDismissed,
  });

  final String message;
  final AppToastKind kind;
  final Duration visibleFor;
  final VoidCallback onDismissed;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
    reverseDuration: AppMotion.fast,
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.visibleFor, _dismiss);
  }

  @override
  void dispose() {
    // WAJIB dibatalkan. Timer yang masih hidup setelah widget-nya hilang akan
    // memanggil setState pada state yang sudah dibuang — dan di test, timer
    // yang menggantung membuat testnya gagal dengan pesan yang menyesatkan.
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    _timer?.cancel();

    // Animasi keluar dijalankan dulu, baru entry-nya dilepas. `mounted` dicek
    // ulang setelah await karena widget bisa saja sudah hilang duluan —
    // misalnya pesan baru menggantikan yang ini.
    await _controller.reverse();

    if (mounted) widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isError = widget.kind == AppToastKind.failure;

    // Berhasil dan info memakai permukaan netral — warnanya hanya di garis tepi
    // dan ikon. Kegagalan memakai bidang merah lembut, karena itu satu-satunya
    // pesan yang harus terbaca sebelum siswa sempat membaca kalimatnya.
    final tint = isError ? colors.errorContainer : null;
    final foreground = isError ? colors.onErrorContainer : colors.onSurface;
    final accent = switch (widget.kind) {
      AppToastKind.success => AppSemantic.success(theme.brightness),
      AppToastKind.info => AppSemantic.info(theme.brightness),
      AppToastKind.failure => colors.error,
    };

    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enter,
      reverseCurve: Curves.easeIn,
    );

    return Positioned(
      // Di bawah poni/status bar, bukan menimpanya.
      top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          // Turun sedikit dari arah atas — arah geraknya memberi tahu dari mana
          // pesan ini datang dan ke mana ia akan pergi.
          position: Tween<Offset>(
            begin: const Offset(0, -0.35),
            end: Offset.zero,
          ).animate(curved),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxToastWidth,
              ),
              child: GlassPanel(
                radius: AppSpacing.radiusLg,
                tint: tint,
                padding: EdgeInsets.zero,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    // Ketuk untuk menutup lebih cepat, tanpa menunggu.
                    onTap: _dismiss,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        // Garis tepi berwarna DI ATAS garis kaca: inilah yang
                        // membedakan berhasil dari info, karena isian keduanya
                        // sama-sama netral.
                        border: Border.all(
                          color: accent.withValues(
                            alpha: isError ? 0.40 : 0.45,
                          ),
                          width: 1.2,
                        ),
                      ),
                      // Vertikalnya lebih rapat dari horizontal, dan sengaja
                      // lebih rapat dari kontrol lain: pesan sekilas melayang di
                      // atas konten, jadi tingginya langsung terasa sebagai
                      // sesuatu yang menutupi. Ia juga tidak wajib diketuk —
                      // hilang sendiri — jadi aturan 48 tidak berlaku di sini.
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md + AppSpacing.xs,
                        vertical: AppSpacing.sm,
                      ),
                      // `liveRegion` membuat pembaca layar membacakan pesan ini
                      // begitu muncul, tanpa perlu memindahkan fokus ke sini.
                      child: Semantics(
                        liveRegion: true,
                        container: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_icon, size: 20, color: accent),
                            const SizedBox(
                              width: AppSpacing.sm + AppSpacing.xs,
                            ),
                            Flexible(
                              child: Text(
                                widget.message,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (widget.kind) {
    AppToastKind.success => Icons.check_circle_rounded,
    AppToastKind.info => Icons.info_rounded,
    AppToastKind.failure => Icons.error_rounded,
  };
}
