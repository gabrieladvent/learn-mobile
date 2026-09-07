import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_background.dart';
import '../../../core/ui/glass_surface.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/student.dart';
import '../../app_update/presentation/optional_update_banner.dart';

/// Beranda — masih kerangka.
///
/// TODO(Fase 2): daftar mata pelajaran, statistik, dan to-do list dari
/// `GET /dashboard` dan `GET /todo`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authControllerProvider).value?.student;
    final theme = Theme.of(context);

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            kToolbarHeight + AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.md,
          ),
          children: [
            const OptionalUpdateBanner(),
            _ProfileCard(student: student),
            const SizedBox(height: AppSpacing.md),
            SoftCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              radius: AppSpacing.radiusLg,
              child: Column(
                children: [
                  Icon(
                    Icons.construction_outlined,
                    size: 40,
                    color: context.accents[2].base,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Mata pelajaran dan tugas belum tersedia',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Bagian ini menyusul di tahap berikutnya.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.student});

  final Student? student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final student = this.student;
    final accent = context.accents[(student?.fullName.length ?? 0)];

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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (student?.className != null)
                  Text(
                    student!.className!,
                    style: theme.textTheme.bodyMedium?.copyWith(
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

    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
