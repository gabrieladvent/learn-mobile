import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_background.dart';
import '../../../core/ui/glass_surface.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/update/force_update_controller.dart';
import '../../../core/update/store_launcher.dart';

class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(forceUpdateControllerProvider);
    final theme = Theme.of(context);
    final storeUrl = info?.storeUrl;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.system_update_rounded,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Perbarui aplikasi dulu',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          info?.message ?? 'Versi aplikasi kamu sudah terlalu lama untuk dipakai.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),

                        if (info?.minVersion != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Versi minimum: ${info!.minVersion}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xl),
                        if (storeUrl != null)
                          FilledButton.icon(
                            onPressed: () => _openStore(context, storeUrl),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Perbarui sekarang'),
                          )
                        else
                          Text(
                            'Buka Play Store atau App Store, lalu perbarui '
                            'aplikasi ini.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context, String url) async {
    final toast = AppToast.of(context);

    if (!await openStoreUrl(url)) {
      toast.showFailure(
        'Tidak bisa membuka toko aplikasi. Buka Play Store atau App Store '
        'secara manual, lalu perbarui aplikasi ini.',
      );
    }
  }
}
