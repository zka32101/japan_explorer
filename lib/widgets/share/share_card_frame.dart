import 'package:flutter/material.dart';

import '../../config/app_brand.dart';
import '../../config/theme.dart';
import '../theme/globe_grid_painter.dart';

/// Seasonal look of a share card. [classic] is the year-round vermilion one.
enum CardFrameStyle { sakura, summer, momiji, snow, classic }

extension CardFrameStyleX on CardFrameStyle {
  String get emoji => switch (this) {
        CardFrameStyle.sakura => '🌸',
        CardFrameStyle.summer => '🌻',
        CardFrameStyle.momiji => '🍁',
        CardFrameStyle.snow => '❄️',
        CardFrameStyle.classic => '🗾',
      };

  /// Header gradient (light → dark).
  List<Color> get gradient => switch (this) {
        CardFrameStyle.sakura => const [Color(0xFFFF9DB1), Color(0xFFE0334F)],
        CardFrameStyle.summer => const [Color(0xFF4FC3F7), Color(0xFF0277BD)],
        CardFrameStyle.momiji => const [Color(0xFFFF8A3D), Color(0xFF9C1C1C)],
        CardFrameStyle.snow => const [Color(0xFF90A4C8), Color(0xFF283A66)],
        CardFrameStyle.classic => const [
            AppColors.primaryLight,
            AppColors.primaryDeep,
          ],
      };

  /// Soft tint of the card body.
  Color get paper => switch (this) {
        CardFrameStyle.sakura => const Color(0xFFFFF4F6),
        CardFrameStyle.summer => const Color(0xFFF0F9FF),
        CardFrameStyle.momiji => const Color(0xFFFFF5EA),
        CardFrameStyle.snow => const Color(0xFFF2F5FB),
        CardFrameStyle.classic => AppColors.paper,
      };

  /// The style that matches [date]'s season (Mar–May spring, Jun–Aug summer,
  /// Sep–Nov autumn, Dec–Feb winter).
  static CardFrameStyle forDate(DateTime date) {
    final m = date.month;
    if (m >= 3 && m <= 5) return CardFrameStyle.sakura;
    if (m >= 6 && m <= 8) return CardFrameStyle.summer;
    if (m >= 9 && m <= 11) return CardFrameStyle.momiji;
    return CardFrameStyle.snow;
  }
}

/// A 4:5 card (designed on a 360×450 canvas, captured at 3× → 1080×1350) with
/// the series header, a seasonal decoration and a footer carrying the app name.
/// The page content goes in [child].
class ShareCardFrame extends StatelessWidget {
  const ShareCardFrame({
    super.key,
    required this.style,
    required this.title,
    required this.child,
    this.subtitle,
  });

  static const double width = 360;
  static const double height = 450;
  static const double _headerHeight = 88;
  static const double _footerHeight = 40;

  final CardFrameStyle style;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: style.paper,
          child: Column(
            children: [
              SizedBox(
                height: _headerHeight,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: style.gradient,
                    ),
                  ),
                  child: CustomPaint(
                    painter: const GlobeGridPainter(
                      color: Colors.white,
                      opacity: 0.18,
                      alignment: Alignment(0.8, 0),
                      radiusFactor: 0.8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (subtitle != null)
                                  Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: kMinFontSize,
                                      color: Colors.white70,
                                    ),
                                  ),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(style.emoji,
                              style: const TextStyle(fontSize: 36)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: child,
                ),
              ),
              SizedBox(
                height: _footerHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: style.gradient.last,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'JP',
                          style: TextStyle(
                            fontSize: kMinFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tripBrand.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: kMinFontSize,
                            fontWeight: FontWeight.w600,
                            color: style.gradient.last,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
