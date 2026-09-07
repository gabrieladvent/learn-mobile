import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class AppSubmitButton extends StatelessWidget {
  const AppSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: AppMotion.normal,
        switchInCurve: AppMotion.enter,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: loading
            ? const SizedBox(
                key: ValueKey('loading'),
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, key: ValueKey(label)),
      ),
    );
  }
}
