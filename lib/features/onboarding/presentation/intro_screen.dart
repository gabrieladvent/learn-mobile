import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_background.dart';
import '../application/intro_controller.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _pages = const [
    _IntroPage(
      accentIndex: 0,
      icon: Icons.menu_book_outlined,
      title: 'Materi di satu tempat',
      body:
          'Semua mata pelajaran dan materi dari gurumu tersusun rapi, '
          'siap dibuka kapan saja.',
    ),
    _IntroPage(
      accentIndex: 1,
      icon: Icons.assignment_turned_in_outlined,
      title: 'Tugas dan tenggatnya',
      body:
          'Lihat apa yang harus dikerjakan dan kapan batas waktunya, '
          'lalu kumpulkan langsung dari HP.',
    ),
    _IntroPage(
      accentIndex: 3,
      icon: Icons.timer_outlined,
      title: 'Ujian dengan waktu terjaga',
      body:
          'Waktu ujian dihitung di server, jadi tetap aman walau '
          'sinyalmu sempat putus di tengah jalan.',
    ),
  ];

  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() =>
      ref.read(introControllerProvider.notifier).complete();

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }

    _controller.nextPage(duration: AppMotion.slow, curve: AppMotion.move);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text('Lewati'),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) => setState(() => _index = index),
                  children: _pages,
                ),
              ),
              _Dots(
                count: _pages.length,
                active: _index,
                color: context.accents[_pages[_index].accentIndex].base,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? 'Mulai' : 'Lanjut'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.accentIndex,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int accentIndex;

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = context.accents[accentIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: accent.container,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: accent.onContainer),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active, required this.color});

  final int count;
  final int active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == active;

        return AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.enter,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          height: 8,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive ? color : colors.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
