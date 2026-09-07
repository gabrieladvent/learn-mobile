import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

class AppSubmitButton extends StatefulWidget {
  const AppSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.colors,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final List<Color>? colors;

  @override
  State<AppSubmitButton> createState() => _AppSubmitButtonState();
}

class _AppSubmitButtonState extends State<AppSubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = widget.onPressed != null && !widget.loading;
    final pair = widget.colors ?? [scheme.primary, scheme.tertiary];
    final gradient = [pair.first, Color.lerp(pair.first, pair.last, 0.55)!];
    final glow = pair.first;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.enter,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.6,
        duration: AppMotion.fast,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: glow.withValues(alpha: 0.22),
                      blurRadius: 18,
                      spreadRadius: -6,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              child: SizedBox(
                height: 48,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: AppMotion.normal,
                    switchInCurve: AppMotion.enter,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: widget.loading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.label,
                            key: ValueKey(widget.label),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
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
}
