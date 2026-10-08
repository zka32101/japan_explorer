import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/widgets/startup_splash.dart';

void main() {
  testWidgets('起動画面は、アプリのアイコンと組織ロゴを一枚の画面に出す', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartupSplash()));

    final paths = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => (i.image as AssetImage).assetName)
        .toList();
    expect(paths, contains('assets/branding/app_icon.png'));
    expect(paths, contains('assets/branding/yourwish_logo.png'));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Your Wish'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      StartupSplash.splashBackground,
    );
  });

  testWidgets('ダークモードでは暗い背景色になる', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const MaterialApp(home: StartupSplash()));
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      StartupSplash.splashBackgroundDark,
    );
  });
}
