import 'package:flutter/material.dart';

import '../../../../core/format/schedule_format.dart';
import '../../../../core/theme/app_semantic.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/glass_surface.dart';
import '../../domain/todo_list.dart';

class TodoItemTile extends StatelessWidget {
  const TodoItemTile({
    super.key,
    required this.item,
    this.isNew = false,
    this.onTap,
  });

  final TodoItem item;
  final bool isNew;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = AppSemantic.warning(theme.brightness);
    final tone = item.kind == TodoKind.exam
        ? warning
        : theme.colorScheme.primary;
    final schedule = describeTodoSchedule(item);
    final scheduleColor = item.isToday
        ? warning
        : theme.colorScheme.onSurfaceVariant;

    return SoftCard(
      onTap: onTap,
      radius: AppSpacing.radiusLg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(_icon, size: 22, color: tone),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const _NewLabel(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.title ?? 'Tanpa judul',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (schedule.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        item.isLocked
                            ? Icons.lock_outline_rounded
                            : Icons.schedule_rounded,
                        size: 14,
                        color: scheduleColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          schedule,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheduleColor,
                            fontWeight: item.isToday ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon => switch (item.kind) {
    TodoKind.assignment => Icons.assignment_outlined,
    TodoKind.exam => Icons.quiz_outlined,
    TodoKind.unknown => Icons.checklist_rounded,
  };

  String get _eyebrow {
    final kind = switch (item.kind) {
      TodoKind.assignment => 'Tugas',
      TodoKind.exam => 'Ujian',
      TodoKind.unknown => 'Kegiatan',
    };
    final subject = item.subjectName;

    return subject == null ? kind : '$kind · $subject';
  }
}

class _NewLabel extends StatelessWidget {
  const _NewLabel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        'Baru',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String describeTodoSchedule(TodoItem item, {DateTime? now}) {
  String at(DateTime time) => formatSchedule(time, now: now);

  switch (item.kind) {
    case TodoKind.assignment:
      final deadline = item.deadline;
      return deadline == null ? 'Tanpa tenggat' : 'Tenggat ${at(deadline)}';
    case TodoKind.exam when item.isLocked:
      final startsAt = item.startsAt;
      return startsAt == null ? 'Jadwal menyusul' : 'Mulai ${at(startsAt)}';
    case TodoKind.exam:
      final until = item.availableUntil;
      return until == null ? 'Sedang dibuka' : 'Dibuka sampai ${at(until)}';
    case TodoKind.unknown:
      return '';
  }
}
