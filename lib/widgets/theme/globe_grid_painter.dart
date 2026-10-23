import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Faint globe (meridians + parallels) used as the series' background motif.
///
/// The globe is centred at [alignment] and sized from the shorter side of the
/// canvas ([radiusFactor] × shortestSide), so it reads the same in a tall page
/// and in a wide header.
class GlobeGridPainter extends CustomPainter {
  const GlobeGridPainter({
    required this.color,
    this.opacity = 0.1,
    this.alignment = const Alignment(0.7, 0.2),
    this.radiusFactor = 0.6,
  });

  final Color color;
  final double opacity;
  final Alignment alignment;
  final double radiusFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * radiusFactor;
    final c = alignment.alongSize(size);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: opacity);

    // Meridians
    for (final k in const [0.35, 0.7, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: r * 2 * k * 0.55, height: r * 2 * k),
        line,
      );
    }
    // Parallels (flattened ellipses that follow the sphere)
    for (final y in const [-0.55, 0.0, 0.55]) {
      final w = math.sqrt(1 - y * y) * r;
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(0, y * r),
          width: w * 2,
          height: w * 2 * 0.13,
        ),
        line,
      );
    }
    // Outline
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color.withValues(alpha: math.min(1, opacity * 1.4)),
    );
  }

  @override
  bool shouldRepaint(GlobeGridPainter old) =>
      old.color != color ||
      old.opacity != opacity ||
      old.alignment != alignment ||
      old.radiusFactor != radiusFactor;
}
