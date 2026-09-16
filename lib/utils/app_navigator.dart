import 'package:flutter/material.dart';

import 'page_transitions.dart';

/// Global navigator key — passed to GoRouter so FCM and analytics services
/// can navigate / read context from outside the widget tree.
final appNavigatorKey = GlobalKey<NavigatorState>();

/// Optimized navigation helpers with fast page transitions
class AppNavigator {
  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    bool useSlideUp = false,
  }) {
    final route = useSlideUp
        ? SlideUpPageRoute<T>(builder: (_) => page)
        : OptimizedMaterialPageRoute<T>(builder: (_) => page);
    return Navigator.of(context).push<T>(route);
  }

  static Future<T?> pushFade<T>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push<T>(
      FadeTransitionPageRoute<T>(builder: (_) => page),
    );
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  static void popUntil(BuildContext context, RoutePredicate predicate) {
    Navigator.of(context).popUntil(predicate);
  }
}
