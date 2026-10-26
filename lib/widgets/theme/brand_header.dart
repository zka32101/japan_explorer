import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'globe_grid_painter.dart';

/// Vermilion gradient header with the globe grid and a gently curved bottom
/// edge. Put the greeting/title (and e.g. a search field) in [child]; the
/// content is kept clear of the curve and of the status bar.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.child,
    this.height = 180,
    this.curve = 28,
  });

  final Widget child;

  /// Total height including the curved edge.
  final double height;

  /// How far the bottom edge dips at the centre.
  final double curve;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurveClipper(curve),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDeep],
            stops: [0, 0.55, 1],
          ),
        ),
        child: CustomPaint(
          painter: const GlobeGridPainter(
            color: Colors.white,
            opacity: 0.16,
            alignment: Alignment(0.75, -0.2),
            radiusFactor: 0.9,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, curve + 8),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small greeting + large title in white, the usual content of [BrandHeader].
class BrandHeaderTitle extends StatelessWidget {
  const BrandHeaderTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: kMinFontSize, color: Colors.white70),
          ),
        Text(
          title,
          // 長い言語(フランス語など)で3行になって切れないよう、2行までにする
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _CurveClipper extends CustomClipper<Path> {
  const _CurveClipper(this.curve);

  final double curve;

  @override
  Path getClip(Size size) {
    final h = size.height;
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, h - curve)
      // Control point below the edge so the lowest point lands on y = h.
      ..quadraticBezierTo(size.width / 2, h + curve, 0, h - curve)
      ..close();
  }

  @override
  bool shouldReclip(_CurveClipper old) => old.curve != curve;
}
