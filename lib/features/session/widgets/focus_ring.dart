import 'dart:math';

import 'package:flutter/material.dart';

/// Anneau de progression de la session (1.0 = session qui démarre).
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 240,
  });

  final double progress;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) =>
            CustomPaint(painter: _RingPainter(value), child: child),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(arcRect, 0, 2 * pi, false, track);

    final arc = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(arcRect, -pi / 2, 2 * pi * progress.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
