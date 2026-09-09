import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/glass_surface.dart';
import '../../domain/dashboard.dart';

class UpcomingExamCard extends StatelessWidget {
  const UpcomingExamCard({super.key, required this.exam, this.onTap});

  final UpcomingExam? exam;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final exam = this.exam;
    if (exam == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final accent = AppSemantic.warning(theme.brightness);

    return SoftCard(
      onTap: onTap,
      radius: AppSpacing.radiusLg,
      child: Row(
        children: [
          Icon(Icons.event_note_rounded, color: accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ujian terdekat',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  exam.title ?? 'Ujian',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _subtitle(exam),
                  maxLines: 2,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _subtitle(UpcomingExam exam) {
    final parts = <String>[
      if (exam.subjectName != null) exam.subjectName!,
      if (exam.startsAt != null) formatExamSchedule(exam.startsAt!),
      if (exam.durationMinutes != null) '${exam.durationMinutes} menit',
    ];

    return parts.isEmpty ? 'Jadwal menyusul' : parts.join(' · ');
  }
}

@visibleForTesting
String formatExamSchedule(DateTime startsAt) {
  final local = startsAt.toLocal();
  final day = _days[local.weekday - 1];
  final month = _months[local.month - 1];
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day, ${local.day} $month ${local.hour}.$minute';
}

const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];
