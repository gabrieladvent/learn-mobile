import 'package:flutter/material.dart';

import '../cache/cached.dart';
import '../theme/app_semantic.dart';
import '../theme/app_spacing.dart';

class StaleNotice extends StatelessWidget {
  const StaleNotice({
    super.key,
    required this.cached,
    this.softLimit = const Duration(minutes: 15),
  });

  final Cached<Object?> cached;
  final Duration softLimit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final beyondSoftLimit = cached.age > softLimit;

    final color = beyondSoftLimit
        ? AppSemantic.warning(theme.brightness)
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_off_rounded, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            'Terakhir diperbarui ${formatLastUpdated(cached.age)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: beyondSoftLimit ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}
