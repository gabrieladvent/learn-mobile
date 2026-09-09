import 'package:flutter/material.dart';

import '../../../../core/theme/app_accents.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/glass_surface.dart';
import '../../domain/dashboard.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, this.onTap});

  final CourseSummary course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = course.subjectName ?? 'Mata pelajaran';
    final accent = context.accents[(course.subjectCode ?? name).hashCode.abs()];

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
          if (course.isPinned)
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

    return source.substring(0, source.length < 3 ? source.length : 3)
        .toUpperCase();
  }
}
