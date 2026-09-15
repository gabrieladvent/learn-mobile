import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.height, this.width});

  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memuat',
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface
              .withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
      ),
    );
  }
}
