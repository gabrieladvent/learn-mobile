import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_accents.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/glass_surface.dart';
import '../../domain/dashboard.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    this.isPinned,
    this.onTap,
    this.onTogglePin,
  });

  final CourseSummary course;
  final bool? isPinned;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = course.subjectName ?? 'Mata pelajaran';
    final accent = context.accents[(course.subjectCode ?? name).hashCode.abs()];
    final pinned = isPinned ?? course.isPinned;

    return SoftCard(
      onTap: onTap,
      radius: AppSpacing.radiusLg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.container,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              _badge(course.subjectCode, name),
              style: theme.textTheme.labelLarge?.copyWith(
                color: accent.onContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  course.teacherName ?? 'Guru belum ditentukan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onTogglePin != null)
            _PinButton(pinned: pinned, onPressed: onTogglePin!)
          else if (pinned)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Icon(
                Icons.push_pin_rounded,
                size: 18,
                color: theme.colorScheme.primary,
                semanticLabel: 'Disematkan',
              ),
            ),
        ],
      ),
    );
  }

  static String _badge(String? code, String name) {
    final source = (code == null || code.isEmpty) ? name : code;

    return source
        .substring(0, source.length < 3 ? source.length : 3)
        .toUpperCase();
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({required this.pinned, required this.onPressed});

  final bool pinned;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: pinned ? 'Lepas sematan' : 'Sematkan',
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
          key: ValueKey(pinned),
          size: 20,
          color: pinned
              ? scheme.primary
              : scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
