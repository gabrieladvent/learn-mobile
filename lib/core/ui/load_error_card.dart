import 'package:flutter/material.dart';

import '../error/app_failure.dart';
import '../theme/app_spacing.dart';
import 'glass_surface.dart';

class LoadErrorCard extends StatelessWidget {
  const LoadErrorCard({
    super.key,
    required this.error,
    required this.fallbackMessage,
    required this.onRetry,
  });

  final Object error;
  final String fallbackMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failure = error;

    final message = failure is AppFailure ? failure.message : fallbackMessage;
    final offline = failure is NetworkFailure;

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppSpacing.radiusLg,
      child: Column(
        children: [
          Icon(
            offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            size: 36,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
