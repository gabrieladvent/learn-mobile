import 'package:flutter/material.dart';

import '../error/app_failure.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

class FailureBanner extends StatelessWidget {
  const FailureBanner({super.key, required this.failure});

  final AppFailure? failure;

  @override
  Widget build(BuildContext context) {
    final failure = this.failure;
    final visible = failure != null && failure is! ValidationFailure;

    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.enter,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.normal,
        switchInCurve: AppMotion.enter,
        child: visible
            ? _Message(key: ValueKey(failure.message), failure: failure)
            : const SizedBox(width: double.infinity),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.failure});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: colors.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              failure.message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
