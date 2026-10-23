import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/widgets/theme/app_icons.dart';

void main() {
  test('parseGlyphPath handles M/L/H/V/C/Q/Z and stays inside the 24 grid', () {
    final p = parseGlyphPath('M3 11 L12 3 L21 11 M5 10 V20 H10 Z');
    final b = p.getBounds();
    expect(b.left, 3);
    expect(b.right, 21);
    expect(b.top, 3);
    expect(b.bottom, 20);
    final curve = parseGlyphPath('M3 19 C3 16 6 14 9 14 Q12 14 15 19');
    expect(curve.getBounds().width, greaterThan(10));
    expect(() => parseGlyphPath('M0 0 A5 5 0 0 1 4 4'), throwsFormatException);
  });

  testWidgets('every glyph paints without errors, as icon and as chip', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Wrap(
          children: [
            for (final g in AppGlyph.values) ...[
              AppIcon(g, size: 32),
              AppIconChip(g, size: 48),
            ],
          ],
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(AppIcon), findsNWidgets(AppGlyph.values.length * 2));
  });

  testWidgets('AppIcon follows the IconTheme size', (tester) async {
    // Center loosens the screen-filling constraints so the icon's own size shows.
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: IconTheme(
          data: IconThemeData(size: 40, color: Colors.red),
          child: AppIcon(AppGlyph.home),
        ),
      ),
    ));
    expect(tester.getSize(find.byType(AppIcon)), const Size(40, 40));
  });
}
