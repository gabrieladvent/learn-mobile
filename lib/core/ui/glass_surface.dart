import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

BoxDecoration glassDecoration(
  BuildContext context, {
  required double radius,
  Color? tint,
  bool opaque = false,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final base =
      tint ?? (isDark ? theme.colorScheme.surfaceBright : Colors.white);

  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: base.withValues(
      alpha: opaque ? (isDark ? 0.62 : 0.88) : (isDark ? 0.26 : 0.52),
    ),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.white.withValues(alpha: 0.9),
      width: 1.2,
    ),
    boxShadow: [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.40)
            : theme.colorScheme.primary.withValues(alpha: 0.13),
        blurRadius: 40,
        spreadRadius: -6,
        offset: const Offset(0, 16),
      ),
    ],
  );
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppSpacing.radiusLg,
    this.blur = 28,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: glassDecoration(context, radius: radius, tint: tint),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.06
                        : 0.35,
                  ),
                  Colors.white.withValues(alpha: 0),
                ],
                stops: const [0, 0.55],
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppSpacing.radius,
    this.tint,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: glassDecoration(
        context,
        radius: radius,
        tint: tint,
        opaque: true,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
