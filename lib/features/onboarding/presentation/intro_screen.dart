import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_background.dart';
import '../../../core/ui/app_orb.dart';
import '../../../core/ui/app_submit_button.dart';
import '../../../core/ui/glass_surface.dart';
import '../application/intro_controller.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _pages = const [
    _IntroContent(
      colors: AppGradients.brand,
      icon: Icons.auto_stories_rounded,
      title: 'Materi di satu tempat',
      body:
          'Semua mata pelajaran dan materi dari gurumu tersusun rapi, '
          'siap dibuka kapan saja.',
    ),

    _IntroContent(
      colors: AppGradients.calm,
      icon: Icons.task_alt_rounded,
      title: 'Tugas dan tenggatnya',
      body:
          'Lihat apa yang harus dikerjakan dan kapan batas waktunya, '
          'lalu kumpulkan langsung dari HP.',
    ),
    
    _IntroContent(
      colors: AppGradients.warm,
      icon: Icons.timer_rounded,
      title: 'Ujian dengan waktu terjaga',
      body:
          'Waktu ujian dihitung di server, jadi tetap aman walau '
          'sinyalmu sempat putus di tengah jalan.',
    ),
  ];

  final _controller = PageController();

  double _offset = 0;

  int get _index => _offset.round();

  bool get _isLast => _index == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final page = _controller.page;
      if (page != null && page != _offset) setState(() => _offset = page);
    });
  }

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
    final last = _pages.length - 1;
    final low = _pages[_offset.floor().clamp(0, last)].colors;
    final high = _pages[_offset.ceil().clamp(0, last)].colors;
    final t = _offset - _offset.floorToDouble();

    final gradient = [
      Color.lerp(low.first, high.first, t)!,
      Color.lerp(low.last, high.last, t)!,
    ];
    final tint = gradient.first;

    return Scaffold(
      body: AppBackground(
        tint: tint,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Lewati',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) => _IntroPage(
                    content: _pages[index],
                    distance: index - _offset,
                  ),
                ),
              ),
              PageDots(count: _pages.length, active: _index, color: tint),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppSubmitButton(
                  label: _isLast ? 'Mulai' : 'Lanjut',
                  loading: false,
                  onPressed: _next,
                  colors: gradient,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroContent {
  const _IntroContent({
    required this.colors,
    required this.icon,
    required this.title,
    required this.body,
  });

  final List<Color> colors;
  final IconData icon;
  final String title;
  final String body;
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.content, required this.distance});

  final _IntroContent content;
  final double distance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fade = (1 - distance.abs()).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(distance * -60, 0),
            child: Opacity(
              opacity: fade,
              child: AppOrb(
                icon: content.icon,
                colors: content.colors,
                size: 132,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Transform.translate(
            offset: Offset(distance * -24, 0),
            child: Opacity(
              opacity: fade,
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    GradientTitle(
                      content.title,
                      colors: content.colors,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      content.body,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
