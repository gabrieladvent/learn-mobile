import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero});

  Reveal.at(int step, {super.key, required this.child})
    : delay = Duration(milliseconds: 60 * step);

  final Widget child;
  final Duration delay;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  @override
  void initState() {
    super.initState();

    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }

    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    final curved = CurvedAnimation(parent: _controller, curve: AppMotion.enter);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
