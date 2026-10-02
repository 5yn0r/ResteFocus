import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format.dart';

/// Cadran circulaire pour choisir une durée, façon minuteur natif : un tour
/// complet du cadran vaut 60 minutes, chaque tour supplémentaire ajoute une
/// heure au total affiché au centre.
class DurationDial extends StatefulWidget {
  const DurationDial({
    super.key,
    required this.minutes,
    required this.onChanged,
    this.min = 5,
    this.max = 240,
    this.size = 260,
  });

  final int minutes;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final double size;

  @override
  State<DurationDial> createState() => _DurationDialState();
}

class _DurationDialState extends State<DurationDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _tween;
  late double _displayMinutes;
  bool _dragging = false;
  int? _lastHapticStep;

  @override
  void initState() {
    super.initState();
    _displayMinutes = widget.minutes.toDouble();
    _tween = AlwaysStoppedAnimation(_displayMinutes);
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 350),
        )..addListener(() {
          setState(() => _displayMinutes = _tween.value);
        });
  }

  @override
  void didUpdateWidget(covariant DurationDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && widget.minutes.toDouble() != _displayMinutes) {
      _tween =
          Tween<double>(
            begin: _displayMinutes,
            end: widget.minutes.toDouble(),
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset get _center => Offset(widget.size / 2, widget.size / 2);

  void _updateFromLocalPosition(Offset localPosition, {required bool isDrag}) {
    final vector = localPosition - _center;
    if (vector.distance < 1) return;
    var angle = atan2(vector.dy, vector.dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;
    var minuteOfHour = ((angle / (2 * pi)) * 60).round();
    minuteOfHour = ((minuteOfHour / 5).round() * 5) % 60;

    final currentHours = _displayMinutes.round() ~/ 60;
    var hours = currentHours;

    if (isDrag) {
      final prevMinuteOfHour = _displayMinutes.round() % 60;
      final diff = minuteOfHour - prevMinuteOfHour;
      if (diff > 30) {
        hours -= 1;
      } else if (diff < -30) {
        hours += 1;
      }
    }

    var total = hours * 60 + minuteOfHour;
    total = total.clamp(widget.min, widget.max);

    if (total != _lastHapticStep) {
      HapticFeedback.selectionClick();
      _lastHapticStep = total;
    }

    setState(() => _displayMinutes = total.toDouble());
    if (total != widget.minutes) widget.onChanged(total);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totalMinutes = _displayMinutes.round();
    final minuteOfHourRaw = _displayMinutes % 60;
    final angle = (minuteOfHourRaw / 60) * 2 * pi;

    return GestureDetector(
      onPanStart: (details) {
        _dragging = true;
        _lastHapticStep = _displayMinutes.round();
        _updateFromLocalPosition(details.localPosition, isDrag: true);
      },
      onPanUpdate: (details) =>
          _updateFromLocalPosition(details.localPosition, isDrag: true),
      onPanEnd: (_) => _dragging = false,
      onTapUp: (details) =>
          _updateFromLocalPosition(details.localPosition, isDrag: false),
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _DialPainter(
            angle: angle,
            trackColor: scheme.surfaceContainerHighest,
            primaryColor: scheme.primary,
            tickColor: scheme.outlineVariant,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDuration(totalMinutes),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.schedule_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.angle,
    required this.trackColor,
    required this.primaryColor,
    required this.tickColor,
  });

  final double angle;
  final Color trackColor;
  final Color primaryColor;
  final Color tickColor;

  static const _stroke = 14.0;
  static const _trackInset = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final arcRadius = radius - _trackInset;
    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);

    final tickPaint = Paint()..color = tickColor;
    for (var i = 0; i < 60; i += 5) {
      final isMajor = i % 15 == 0;
      final tAngle = (i / 60) * 2 * pi - pi / 2;
      final outer = Offset(
        center.dx + cos(tAngle) * (radius - 2),
        center.dy + sin(tAngle) * (radius - 2),
      );
      final inner = Offset(
        center.dx + cos(tAngle) * (radius - (isMajor ? 16 : 10)),
        center.dy + sin(tAngle) * (radius - (isMajor ? 16 : 10)),
      );
      canvas.drawLine(
        inner,
        outer,
        tickPaint..strokeWidth = isMajor ? 3 : 1.5,
      );
    }

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, arcRadius, track);

    final arc = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    final sweep = angle == 0 ? 0.0001 : angle;
    canvas.drawArc(arcRect, -pi / 2, sweep, false, arc);

    final handleAngle = -pi / 2 + angle;
    final handleCenter = Offset(
      center.dx + cos(handleAngle) * arcRadius,
      center.dy + sin(handleAngle) * arcRadius,
    );
    canvas.drawCircle(handleCenter, _stroke * 0.85, Paint()..color = primaryColor);
    canvas.drawCircle(handleCenter, _stroke * 0.32, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.angle != angle ||
      old.primaryColor != primaryColor ||
      old.trackColor != trackColor;
}
