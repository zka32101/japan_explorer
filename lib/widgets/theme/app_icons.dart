import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Line-art glyphs of the Showglobe icon set, drawn on a 24×24 grid with
/// round caps/joins (see showglobe_core `brand/theme/board.png`).
///
/// Drawn in code (no extra plugin): each glyph is a few primitives and absolute
/// SVG path data (`M L H V C Q Z`).
enum AppGlyph {
  home,
  map,
  plan,
  people,
  me,
  lens,
  search,
  bowl,
  book,
  sakura,
  trophy,
  globe,
}

/// One stroked shape of a glyph.
class _Shape {
  const _Shape.path(this.d, {this.rotations = const [0]})
      : kind = 0,
        a = 0,
        b = 0,
        c = 0,
        e = 0,
        f = 0;
  const _Shape.circle(this.a, this.b, this.c)
      : kind = 1,
        d = '',
        rotations = const [0],
        e = 0,
        f = 0;
  const _Shape.ellipse(this.a, this.b, this.c, this.e)
      : kind = 2,
        d = '',
        rotations = const [0],
        f = 0;
  const _Shape.rrect(this.a, this.b, this.c, this.e, this.f)
      : kind = 3,
        d = '';

  final int kind; // 0 path, 1 circle, 2 ellipse, 3 rrect
  final String d;
  final List<double> rotations; // degrees about (12, 12), paths only
  final double a, b, c, e, f;
}

const _glyphs = <AppGlyph, List<_Shape>>{
  AppGlyph.home: [
    _Shape.path('M3 11 L12 3 L21 11 M5 10 V20 H10 V14 H14 V20 H19 V10'),
  ],
  AppGlyph.map: [
    _Shape.path('M9 4 L3 6 V20 L9 18 L15 20 L21 18 V4 L15 6 L9 4 Z M9 4 V18 M15 6 V20'),
  ],
  AppGlyph.plan: [
    _Shape.rrect(4, 5, 16, 15, 2),
    _Shape.path('M4 10 H20 M8 3 V7 M16 3 V7'),
  ],
  AppGlyph.people: [
    _Shape.circle(9, 9, 3),
    _Shape.circle(17, 10, 2.5),
    _Shape.path('M3 19 C3 16 6 14 9 14 C12 14 15 16 15 19'),
    _Shape.path('M15 15 C18 15 21 16.5 21 19'),
  ],
  AppGlyph.me: [
    _Shape.circle(12, 8, 4),
    _Shape.path('M4 21 C4 17 8 15 12 15 C16 15 20 17 20 21'),
  ],
  AppGlyph.lens: [
    _Shape.rrect(3, 7, 18, 13, 3),
    _Shape.circle(12, 13.5, 3.5),
    _Shape.path('M9 7 L10.5 4 H13.5 L15 7'),
  ],
  AppGlyph.search: [
    _Shape.circle(11, 11, 6),
    _Shape.path('M16 16 L21 21'),
  ],
  AppGlyph.bowl: [
    _Shape.path('M3 12 H21 C21 17 17 20 12 20 C7 20 3 17 3 12 Z M8 3 L13 10 M12 2 L17 10'),
  ],
  AppGlyph.book: [
    _Shape.path('M4 5 C7 4 9 4 12 6 C15 4 17 4 20 5 V19 C17 18 15 18 12 20 C9 18 7 18 4 19 Z M12 6 V20'),
  ],
  AppGlyph.sakura: [
    _Shape.path('M12 12 C10 9 10 6 12 3 C14 6 14 9 12 12 Z',
        rotations: [0, 72, 144, 216, 288]),
  ],
  AppGlyph.trophy: [
    _Shape.path('M7 4 H17 V9 C17 11.76 14.76 14 12 14 C9.24 14 7 11.76 7 9 Z'),
    _Shape.path('M7 6 H4 V8 C4 9.66 5.34 11 7 11 M17 6 H20 V8 C20 9.66 18.66 11 17 11'),
    _Shape.path('M12 14 V18 M8 21 H16'),
  ],
  AppGlyph.globe: [
    _Shape.circle(12, 12, 9),
    _Shape.ellipse(12, 12, 4, 9),
    _Shape.path('M3 12 H21'),
  ],
};

/// Parses absolute SVG path data (`M L H V C Q Z`) into a [Path].
@visibleForTesting
Path parseGlyphPath(String d) {
  final tokens = RegExp(r'[MLHVCQZ]|-?\d*\.?\d+').allMatches(d).map((m) => m[0]!).toList();
  final path = Path();
  var i = 0;
  var x = 0.0, y = 0.0, startX = 0.0, startY = 0.0;
  double num() => double.parse(tokens[i++]);
  String? cmd;
  while (i < tokens.length) {
    if (RegExp(r'[MLHVCQZ]').hasMatch(tokens[i])) cmd = tokens[i++];
    switch (cmd) {
      case 'M':
        x = num();
        y = num();
        startX = x;
        startY = y;
        path.moveTo(x, y);
        cmd = 'L'; // implicit lineto after the first pair
      case 'L':
        x = num();
        y = num();
        path.lineTo(x, y);
      case 'H':
        x = num();
        path.lineTo(x, y);
      case 'V':
        y = num();
        path.lineTo(x, y);
      case 'C':
        {
          final x1 = num(), y1 = num(), x2 = num(), y2 = num();
          x = num();
          y = num();
          path.cubicTo(x1, y1, x2, y2, x, y);
        }
      case 'Q':
        {
          final x1 = num(), y1 = num();
          x = num();
          y = num();
          path.quadraticBezierTo(x1, y1, x, y);
        }
      case 'Z':
        path.close();
        x = startX;
        y = startY;
      default:
        throw FormatException('Unsupported path command', d);
    }
  }
  return path;
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color, this.strokeWidth);

  final AppGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final s in _glyphs[glyph]!) {
      switch (s.kind) {
        case 0:
          final p = parseGlyphPath(s.d);
          for (final deg in s.rotations) {
            if (deg == 0) {
              canvas.drawPath(p, paint);
            } else {
              canvas
                ..save()
                ..translate(12, 12)
                ..rotate(deg * math.pi / 180)
                ..translate(-12, -12)
                ..drawPath(p, paint)
                ..restore();
            }
          }
        case 1:
          canvas.drawCircle(Offset(s.a, s.b), s.c, paint);
        case 2:
          canvas.drawOval(Rect.fromCenter(center: Offset(s.a, s.b), width: s.c * 2, height: s.e * 2), paint);
        default:
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(s.a, s.b, s.c, s.e), Radius.circular(s.f)),
            paint,
          );
      }
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color || old.strokeWidth != strokeWidth;
}

/// Line-art icon. Size and colour default to the surrounding [IconTheme], so it
/// can be used wherever an [Icon] is (e.g. `NavigationDestination.icon`).
class AppIcon extends StatelessWidget {
  const AppIcon(this.glyph, {super.key, this.size, this.color, this.strokeWidth = 2});

  final AppGlyph glyph;
  final double? size;
  final Color? color;

  /// Stroke width on the 24-unit grid.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? 24;
    return Semantics(
      excludeSemantics: true,
      child: SizedBox(
        width: s,
        height: s,
        child: CustomPaint(
          painter: _GlyphPainter(glyph, color ?? theme.color ?? AppColors.primary, strokeWidth),
        ),
      ),
    );
  }
}

/// Glossy vermilion disc with a white glyph — for emphasised actions
/// (quick-menu entries, empty states).
class AppIconChip extends StatelessWidget {
  const AppIconChip(this.glyph, {super.key, this.size = 56});

  final AppGlyph glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.45),
          radius: 1.0,
          colors: [Color(0xFFFF6A80), AppColors.primary, AppColors.primaryDeep],
          stops: [0, 0.5, 1],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5),
        boxShadow: AppShadows.soft,
      ),
      alignment: Alignment.center,
      child: AppIcon(glyph, size: size * 0.5, color: Colors.white, strokeWidth: 1.8),
    );
  }
}
