import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppOrb extends StatefulWidget {
  const AppOrb({
    super.key,
    required this.icon,
    required this.colors,
    this.size = 96,
  });

  final IconData icon;

  final List<Color> colors;

  final double size;

  @override
  State<AppOrb> createState() => _AppOrbState();
}

class _AppOrbState extends State<AppOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = widget.colors;
    final glow = colors.last;

    final orb = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(colors.first, Colors.white, 0.22)!, colors.last],
        ),

        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: isDark ? 0.34 : 0.20),
            blurRadius: 56,
            spreadRadius: -14,
            offset: const Offset(0, 18),
          ),
        ],

        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.55),
          width: 1.4,
        ),
      ),
      child: Icon(widget.icon, size: widget.size * 0.42, color: Colors.white),
    );

    if (still) return orb;

    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) =>
          Transform.scale(scale: 1 + (_breath.value * 0.03), child: child),
      child: orb,
    );
  }
}

class GradientTitle extends StatelessWidget {
  const GradientTitle(
    this.text, {
    super.key,
    required this.colors,
    this.style,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final List<Color> colors;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.first, Color.lerp(colors.first, colors.last, 0.5)!],
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: (style ?? theme.textTheme.headlineMedium)?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 1.1,
          color: Colors.white,
        ),
      ),
    );
  }
}

class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.active,
    required this.color,
  });

  final int count;
  final int active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == active;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          height: 8,
          width: isActive ? 32 : 8,
          decoration: BoxDecoration(
            color: isActive
                ? color
                : colors.onSurfaceVariant.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isActive ? 0.26 : 0),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        );
      }),
    );
  }
}
