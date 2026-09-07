import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_semantic.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/glass_surface.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/update/store_launcher.dart';
import '../../../core/update/update_check.dart';

class OptionalUpdateBanner extends ConsumerWidget {
  const OptionalUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(optionalUpdateProvider);

    if (info == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final storeUrl = info.storeUrl;
    final accent = AppSemantic.info(theme.brightness);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SoftCard(
        radius: AppSpacing.radiusLg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.system_update_rounded, color: accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Versi ${info.latestVersion} sudah tersedia',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (storeUrl != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      onPressed: () => _openStore(context, storeUrl),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Perbarui'),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Tutup',
              color: theme.colorScheme.onSurfaceVariant,
              onPressed: () =>
                  ref.read(updateBannerDismissedProvider.notifier).dismiss(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context, String url) async {
    final toast = AppToast.of(context);

    if (!await openStoreUrl(url)) {
      toast.showFailure('Tidak bisa membuka toko aplikasi.');
    }
  }
}
