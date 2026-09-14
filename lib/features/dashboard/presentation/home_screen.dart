import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cached.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_semantic.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_background.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/glass_surface.dart';
import '../../app_update/presentation/optional_update_banner.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/student.dart';
import '../application/course_pin_controller.dart';
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
          _LogoutButton(
            onPressed: ref.read(authControllerProvider.notifier).logout,
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
              _ProfileCard(student: student, meta: dashboard.value?.value.meta),
              const SizedBox(height: AppSpacing.md),
              if (dashboard.hasValue)
                _DashboardBody(cached: dashboard.requireValue)
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Kamu perlu memasukkan NISN dan password lagi untuk masuk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: IconButton(
        onPressed: () => _confirm(context),
        tooltip: 'Keluar',
        icon: const Icon(Icons.logout_rounded, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.72),
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          shape: const CircleBorder(),
          minimumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.cached});

  final Cached<Dashboard> cached;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dashboard = cached.value;
    final pinOverrides = ref.watch(coursePinControllerProvider);
    final courses = dashboard.courses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cached.refreshFailed) ...[
          _StaleNotice(cached: cached),
          const SizedBox(height: AppSpacing.sm),
        ],
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
            CourseCard(
              course: course,
              isPinned: pinOverrides[course.id] ?? course.isPinned,
              onTogglePin: () => _togglePin(
                context,
                ref,
                course.id,
                pinned: !(pinOverrides[course.id] ?? course.isPinned),
              ),
            ),
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

  Future<void> _togglePin(
    BuildContext context,
    WidgetRef ref,
    String courseId, {
    required bool pinned,
  }) async {
    final toast = AppToast.of(context);

    try {
      await ref
          .read(coursePinControllerProvider.notifier)
          .toggle(courseId, pinned: pinned);
    } on AppFailure catch (failure) {
      toast.showFailure(
        failure is NetworkFailure
            ? 'Belum tersimpan — periksa koneksimu, lalu coba lagi.'
            : failure.message,
      );
    }
  }
}

class _StaleNotice extends StatelessWidget {
  const _StaleNotice({required this.cached});

  final Cached<Object?> cached;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final beyondSoftLimit = cached.age > _softLimit;

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

const _softLimit = Duration(minutes: 15);

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          padding: EdgeInsets.zero,
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
          color: Theme.of(context).colorScheme.onSurface
              .withValues(alpha: 0.06),
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
