import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

extension AppSnackBar on ScaffoldMessengerState {
  void showSuccess(String message) => _show(message, error: false);

  void showFailure(String message) => _show(message, error: true);

  void _show(String message, {required bool error}) {
    final colors = Theme.of(context).colorScheme;
    final background = error ? colors.errorContainer : colors.inverseSurface;
    final foreground = error ? colors.onErrorContainer : colors.onInverseSurface;

    hideCurrentSnackBar();

    showSnackBar(
      SnackBar(
        backgroundColor: background,
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              size: 20,
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}
