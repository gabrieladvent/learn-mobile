import 'package:flutter/material.dart';

import '../../../../core/theme/app_accents.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/glass_surface.dart';
import '../../domain/dashboard.dart';

class DashboardStatsRow extends StatelessWidget {
  const DashboardStatsRow({super.key, required this.stats});

  final DashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    final stats = this.stats;
    if (stats == null) return const SizedBox.shrink();

    final tiles = [
      _Tile(
        label: 'Tugas belum selesai',
        value: '${stats.assignmentsPending}',
        icon: Icons.assignment_outlined,
        accentIndex: 0,
      ),
      _Tile(
        label: 'Tugas selesai',
        value: '${stats.assignmentsCompleted}',
        icon: Icons.assignment_turned_in_outlined,
        accentIndex: 1,
      ),
      _Tile(
        label: 'Ujian selesai',
        value: '${stats.examsCompleted}',
        icon: Icons.fact_check_outlined,
        accentIndex: 2,
      ),
      _Tile(
        label: 'Rata-rata nilai',
        value: stats.avgScore == null ? '—' : _formatScore(stats.avgScore!),
        icon: Icons.trending_up_rounded,
        accentIndex: 3,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.65,
      children: tiles,
    );
  }

  static String _formatScore(double score) {
    final rounded = (score * 10).round() / 10;

    return rounded == rounded.roundToDouble()
        ? '${rounded.round()}'
        : rounded.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentIndex,
  });

  final String label;
  final String value;
  final IconData icon;
  final int accentIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = context.accents[accentIndex];

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: accent.base),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
