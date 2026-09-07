import 'package:flutter/material.dart';

import 'app_accents.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static const Color _seed = Color(0xFF2563EB);
  static final ThemeData light = _build(Brightness.light);

  static final ThemeData dark = _build(Brightness.dark);

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusField),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.md + 2,
        ),
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        border: _fieldBorder(colors.outlineVariant),
        enabledBorder: _fieldBorder(colors.outlineVariant),
        focusedBorder: _fieldBorder(colors.primary, width: 2),
        errorBorder: _fieldBorder(colors.error, width: 1.5),
        focusedErrorBorder: _fieldBorder(colors.error, width: 2),
        disabledBorder: _fieldBorder(
          colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: shape,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLow,
        shape: shape,
        margin: EdgeInsets.zero,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        elevation: 4,
      ),

      dividerTheme: DividerThemeData(
        space: AppSpacing.lg,
        color: colors.outlineVariant,
      ),

      extensions: [AppAccents.of(brightness)],
    );
  }
}
