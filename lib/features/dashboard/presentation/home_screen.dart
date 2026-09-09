import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_background.dart';
import '../../../core/ui/glass_surface.dart';
import '../../app_update/presentation/optional_update_banner.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/student.dart';
import '../application/dashboard_controller.dart';
import '../domain/dashboard.dart';
import 'widgets/course_card.dart';
import 'widgets/dashboard_stats_row.dart';
import 'widgets/upcoming_exam_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authControllerProvider).value?.student;
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              kToolbarHeight + AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              const OptionalUpdateBanner(),
              _ProfileCard(student: student, meta: dashboard.value?.meta),
              const SizedBox(height: AppSpacing.md),
              if (dashboard.hasValue)
                _DashboardBody(dashboard: dashboard.requireValue)
              else if (dashboard.hasError)
                _ErrorState(
                  error: dashboard.error!,
                  onRetry: () => ref.invalidate(dashboardProvider),
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

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courses = dashboard.courses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardStatsRow(stats: dashboard.stats),
        if (dashboard.stats?.upcomingExam != null) ...[
          const SizedBox(height: AppSpacing.md),
          UpcomingExamCard(exam: dashboard.stats!.upcomingExam),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Mata pelajaran',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (courses.isEmpty)
          const _EmptyCourses()
        else
          for (final course in courses) ...[
            CourseCard(course: course),
            const SizedBox(height: AppSpacing.sm),
          ],
        if (dashboard.meta?.inspire case final quote?) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.65,
          children: const [_Skeleton(), _Skeleton(), _Skeleton(), _Skeleton()],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < 3; i++) ...[
          const _Skeleton(height: 78),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memuat',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final message = error is AppFailure
        ? (error as AppFailure).message
        : 'Beranda tidak bisa dimuat.';
    final offline = error is NetworkFailure;

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

class _EmptyCourses extends StatelessWidget {
  const _EmptyCourses();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppSpacing.radiusLg,
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 36,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Belum ada mata pelajaran',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Hubungi wali kelasmu kalau ini terasa keliru.',
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.student, this.meta});

  final Student? student;
  final DashboardMeta? meta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final student = this.student;
    final accent = context.accents[student?.fullName.length ?? 0];

    final subtitle = [
      if (meta?.classroomName != null) meta!.classroomName!,
      if (meta?.academicYear != null) meta!.academicYear!,
    ].join(' · ');

    return SoftCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: accent.container,
            backgroundImage: student?.photoUrl != null
                ? NetworkImage(student!.photoUrl!)
                : null,
            child: student?.photoUrl == null
                ? Text(
                    _initials(student?.fullName),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: accent.onContainer,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo,',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  student?.fullName ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  static String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'))
      ..removeWhere((part) => part.isEmpty);

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();

    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
