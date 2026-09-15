import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cached.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_background.dart';
import '../../../core/ui/glass_surface.dart';
import '../../../core/ui/load_error_card.dart';
import '../../../core/ui/skeleton_box.dart';
import '../../../core/ui/stale_notice.dart';
import '../application/todo_controller.dart';
import '../application/todo_seen_controller.dart';
import '../domain/todo_list.dart';
import 'widgets/todo_item_tile.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(todoProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('To-do'),
      ),
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(todoProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              kToolbarHeight + AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              if (todo.hasValue)
                _TodoBody(cached: todo.requireValue)
              else if (todo.hasError)
                LoadErrorCard(
                  error: todo.error!,
                  fallbackMessage: 'To-do tidak bisa dimuat.',
                  onRetry: () => ref.invalidate(todoProvider),
                )
              else
                const _LoadingState(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoBody extends ConsumerWidget {
  const _TodoBody({required this.cached});

  final Cached<TodoList> cached;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = cached.value;
    final highlighted =
        ref.watch(todoSeenControllerProvider).value?.highlighted ?? const {};
    final sections = [
      (title: 'Hari ini', items: list.today),
      (title: 'Minggu ini', items: list.restOfWeek),
      (title: 'Nanti', items: list.later),
    ].where((section) => section.items.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cached.refreshFailed) ...[
          StaleNotice(cached: cached),
          const SizedBox(height: AppSpacing.md),
        ],
        if (list.isEmpty)
          const _EmptyTodo()
        else
          for (final (index, section) in sections.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.lg),
            _SectionHeader(title: section.title, count: section.items.length),
            const SizedBox(height: AppSpacing.sm),
            for (final item in section.items) ...[
              TodoItemTile(item: item, isNew: highlighted.contains(item.key)),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyTodo extends StatelessWidget {
  const _EmptyTodo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppSpacing.radiusLg,
      child: Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 36,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tidak ada yang menunggu',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tugas dan ujian yang belum dikerjakan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(height: 22, width: 110),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < 4; i++) ...[
          const SkeletonBox(height: 84),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
