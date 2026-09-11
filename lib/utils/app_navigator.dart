import 'package:flutter/material.dart';

/// Global navigator key — passed to GoRouter so FCM and analytics services
/// can navigate / read context from outside the widget tree.
final appNavigatorKey = GlobalKey<NavigatorState>();
