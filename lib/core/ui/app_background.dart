import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child, this.tint});

  final Widget child;

  final Color? tint;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final still = MediaQuery.disableAnimationsOf(context);

    final palette = <Color>[
      widget.tint ?? const Color(0xFF8B5CF6),
      const Color(0xFF6366F1),
      const Color(0xFF22D3EE),
      const Color(0xFFFB923C),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _drift,
                builder: (context, _) {
                  final t = still ? 0.0 : _drift.value * 2 * math.pi;

                  return Stack(
                    children: [
                      _Blob(
                        base: const Alignment(-1.05, -0.9),
                        drift: Offset(math.sin(t) * 0.12, math.cos(t) * 0.08),
                        diameter: 560,
                        color: palette[0].withValues(
                          alpha: isDark ? 0.22 : 0.17,
                        ),
                      ),

                      _Blob(
                        base: const Alignment(1.15, -0.55),
                        drift: Offset(
                          math.cos(t * 0.8) * 0.10,
                          math.sin(t * 0.8) * 0.12,
                        ),
                        diameter: 460,
                        color: palette[1].withValues(
                          alpha: isDark ? 0.20 : 0.15,
                        ),
                      ),

                      _Blob(
                        base: const Alignment(-0.85, 0.95),
                        drift: Offset(
                          math.sin(t * 1.2 + 1) * 0.12,
                          math.cos(t * 1.2 + 1) * 0.07,
                        ),
                        diameter: 520,
                        color: palette[2].withValues(
                          alpha: isDark ? 0.17 : 0.12,
                        ),
                      ),

                      _Blob(
                        base: const Alignment(1.1, 1.05),
                        drift: Offset(
                          math.cos(t * 0.6 + 2) * 0.09,
                          math.sin(t * 0.6 + 2) * 0.10,
                        ),
                        diameter: 420,
                        color: palette[3].withValues(
                          alpha: isDark ? 0.14 : 0.10,
                        ),
                      ),

                      _Blob(
                        base: const Alignment(-0.15, 0.6),
                        drift: Offset(
                          math.sin(t * 0.5 + 3) * 0.07,
                          math.cos(t * 0.5 + 3) * 0.06,
                        ),
                        diameter: 640,
                        color: palette[0].withValues(
                          alpha: isDark ? 0.12 : 0.09,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.base,
    required this.drift,
    required this.diameter,
    required this.color,
  });

  final Alignment base;
  final Offset drift;
  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(base.x + drift.dx, base.y + drift.dy),
      child: IgnorePointer(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color,
                  color.withValues(alpha: color.a * 0.45),
                  color.withValues(alpha: 0),
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
