import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Optimized Material page route with shorter animation duration
class OptimizedMaterialPageRoute<T> extends MaterialPageRoute<T> {
  OptimizedMaterialPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
    builder: builder,
    settings: settings,
    maintainState: maintainState,
    fullscreenDialog: fullscreenDialog,
  );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);
}

/// Optimized Cupertino page route with shorter animation duration
class OptimizedCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  OptimizedCupertinoPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
    builder: builder,
    settings: settings,
    maintainState: maintainState,
    fullscreenDialog: fullscreenDialog,
  );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);
}

/// Fast fade transition page route
class FadeTransitionPageRoute<T> extends PageRoute<T> {
  FadeTransitionPageRoute({
    required this.builder,
    RouteSettings? settings,
    this.maintainState = true,
    this.fullscreenDialog = false,
  }) : super(settings: settings, fullscreenDialog: fullscreenDialog);

  final WidgetBuilder builder;
  final bool maintainState;
  final bool fullscreenDialog;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

/// Slide up + fade transition page route (for modals)
class SlideUpPageRoute<T> extends PageRoute<T> {
  SlideUpPageRoute({
    required this.builder,
    RouteSettings? settings,
    this.maintainState = true,
  }) : super(settings: settings, fullscreenDialog: false);

  final WidgetBuilder builder;
  final bool maintainState;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.5);

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    final tween = Tween(begin: begin, end: end)
        .chain(CurveTween(curve: curve));

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}
