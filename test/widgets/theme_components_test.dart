import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/widgets/theme/brand_header.dart';
import 'package:japan_explorer/widgets/theme/paper_background.dart';

Widget _app(Widget body, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: body),
    );

void main() {
  testWidgets('PaperBackground shows its child in light and dark themes',
      (tester) async {
    for (final b in Brightness.values) {
      await tester.pumpWidget(_app(
        const PaperBackground(child: Center(child: Text('hello'))),
        brightness: b,
      ));
      expect(find.text('hello'), findsOneWidget);
    }
  });

  testWidgets('BrandHeader keeps title and subtitle and has the given height',
      (tester) async {
    await tester.pumpWidget(_app(const Column(
      children: [
        BrandHeader(
          height: 200,
          child: BrandHeaderTitle(title: 'Discover Japan', subtitle: 'Hello'),
        ),
      ],
    )));
    expect(find.text('Discover Japan'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(tester.getSize(find.byType(BrandHeader)).height, 200);
  });

  testWidgets('BrandHeader does not overflow with a tall child at small sizes',
      (tester) async {
    await tester.pumpWidget(_app(const Column(
      children: [
        BrandHeader(
          height: 180,
          child: BrandHeaderTitle(title: 'A', subtitle: 'b'),
        ),
      ],
    )));
    expect(tester.takeException(), isNull);
  });
}
