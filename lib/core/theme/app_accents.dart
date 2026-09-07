import 'package:flutter/material.dart';

class AppAccent {
  const AppAccent({
    required this.base,
    required this.container,
    required this.onContainer,
  });

  final Color base;

  final Color container;

  final Color onContainer;

  static AppAccent lerp(AppAccent a, AppAccent b, double t) => AppAccent(
    base: Color.lerp(a.base, b.base, t)!,
    container: Color.lerp(a.container, b.container, t)!,
    onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
  );
}

@immutable
class AppAccents extends ThemeExtension<AppAccents> {
  const AppAccents(this.swatches);

  final List<AppAccent> swatches;

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

extension AppAccentsContext on BuildContext {
  AppAccents get accents => Theme.of(this).extension<AppAccents>()!;
}
