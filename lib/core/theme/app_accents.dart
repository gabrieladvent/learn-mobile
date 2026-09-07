import 'package:flutter/material.dart';

/// Satu warna aksen lengkap dengan pasangannya.
class AppAccent {
  const AppAccent({
    required this.base,
    required this.container,
    required this.onContainer,
  });

  /// Untuk ikon dan garis — pekat, kontras di atas latar biasa.
  final Color base;

  /// Latar lembut untuk kartu atau lingkaran ikon.
  final Color container;

  /// Warna teks/ikon yang dijamin terbaca DI ATAS [container].
  final Color onContainer;

  static AppAccent lerp(AppAccent a, AppAccent b, double t) => AppAccent(
        base: Color.lerp(a.base, b.base, t)!,
        container: Color.lerp(a.container, b.container, t)!,
        onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
      );
}

/// Palet aksen — warna yang dipakai untuk MEMBEDAKAN isi, bukan untuk chrome.
///
/// `ColorScheme` bawaan Material menangani rangka aplikasi: tombol, latar,
/// permukaan. Semuanya diturunkan dari satu warna induk, jadi menurut desain
/// memang seragam — dan itu yang bikin aplikasi terasa "satu warna saja".
///
/// Palet ini melengkapinya. Dipakai untuk hal yang justru HARUS berbeda satu
/// sama lain: halaman intro, nanti kartu mata pelajaran, penanda status tugas.
/// Warna jadi informasi, bukan hiasan — siswa mengenali "Matematika" dari
/// warnanya sebelum sempat membaca namanya.
///
/// Tiap aksen tetap dilahirkan lewat `ColorScheme.fromSeed`, bukan ditulis
/// tangan. Itu yang menjamin kontrasnya aman di mode terang MAUPUN gelap —
/// warna tetap yang dipilih dengan mata hampir selalu gagal di salah satunya.
@immutable
class AppAccents extends ThemeExtension<AppAccents> {
  const AppAccents(this.swatches);

  final List<AppAccent> swatches;

  /// Lima rona yang sengaja berjauhan di lingkaran warna, supaya masih
  /// terbedakan oleh mata yang sulit membedakan merah-hijau.
  static const _hues = [
    Color(0xFF2563EB), // biru
    Color(0xFF0D9488), // toska
    Color(0xFFF59E0B), // kuning bunga matahari
    Color(0xFF7C3AED), // ungu
    Color(0xFFE11D48), // merah mawar
  ];

  factory AppAccents.of(Brightness brightness) {
    return AppAccents([
      for (final hue in _hues)
        () {
          final scheme = ColorScheme.fromSeed(
            seedColor: hue,
            brightness: brightness,
            dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
          );

          return AppAccent(
            base: scheme.primary,
            container: scheme.primaryContainer,
            onContainer: scheme.onPrimaryContainer,
          );
        }(),
    ]);
  }

  /// Berputar kalau indeksnya melewati jumlah warna — jadi daftar sepanjang
  /// apa pun tetap dapat warna tanpa perlu pengecekan di tiap pemanggil.
  AppAccent operator [](int index) => swatches[index % swatches.length];

  @override
  AppAccents copyWith({List<AppAccent>? swatches}) =>
      AppAccents(swatches ?? this.swatches);

  @override
  AppAccents lerp(covariant AppAccents? other, double t) {
    if (other == null) return this;

    return AppAccents([
      for (var i = 0; i < swatches.length; i++)
        AppAccent.lerp(swatches[i], other.swatches[i], t),
    ]);
  }
}

/// Jalan pintas: `context.accents[2]` alih-alih
/// `Theme.of(context).extension<AppAccents>()!`.
extension AppAccentsContext on BuildContext {
  AppAccents get accents => Theme.of(this).extension<AppAccents>()!;
}
