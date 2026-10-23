import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'globe_grid_painter.dart';

/// Page background: washi paper with a very faint globe grid (light), or a
/// night-sky gradient with the same globe (dark). Follows the theme brightness.
///
/// It sizes to [child]; wrap it in an `Expanded`/`SizedBox.expand` (or use it as
/// a `Scaffold` body with a scrollable child) so it fills the screen.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [AppColors.nightSurface, AppColors.night]
              : const [Colors.white, AppColors.paper],
        ),
      ),
      child: CustomPaint(
        painter: GlobeGridPainter(
          color: dark ? Colors.white : AppColors.primary,
          opacity: dark ? 0.08 : 0.07,
          alignment: const Alignment(0.8, 0.75),
          radiusFactor: 0.7,
        ),
        child: child,
      ),
    );
  }
}
