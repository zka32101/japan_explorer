import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/widgets/share/share_card_frame.dart';
import 'package:japan_explorer/widgets/share/share_card_sheet.dart';

void main() {
  test('forDate picks the season of the month', () {
    CardFrameStyle at(int m) => CardFrameStyleX.forDate(DateTime(2026, m, 15));
    expect(at(3), CardFrameStyle.sakura);
    expect(at(5), CardFrameStyle.sakura);
    expect(at(6), CardFrameStyle.summer);
    expect(at(8), CardFrameStyle.summer);
    expect(at(9), CardFrameStyle.momiji);
    expect(at(11), CardFrameStyle.momiji);
    expect(at(12), CardFrameStyle.snow);
    expect(at(1), CardFrameStyle.snow);
    expect(at(2), CardFrameStyle.snow);
  });

  testWidgets('ShareCardFrame shows title, subtitle, content and the brand',
      (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: ShareCardFrame(
            style: CardFrameStyle.classic,
            title: 'Fushimi Inari',
            subtitle: 'AI Lens',
            child: Text('body'),
          ),
        ),
      ),
    ));
    expect(find.text('Fushimi Inari'), findsOneWidget);
    expect(find.text('AI Lens'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
    expect(find.text('JP'), findsOneWidget);
    expect(t.getSize(find.byType(ShareCardFrame)),
        const Size(ShareCardFrame.width, ShareCardFrame.height));
  });

  testWidgets('sheet lets the user switch the seasonal frame', (t) async {
    await t.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showShareCardSheet(
            context,
            cardBuilder: (_, style) => ShareCardFrame(
              style: style,
              title: 'T',
              child: Text('style:${style.name}'),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    // One chip per style.
    for (final s in CardFrameStyle.values) {
      expect(find.widgetWithText(ChoiceChip, s.emoji), findsOneWidget);
    }
    await t.tap(find.widgetWithText(ChoiceChip, CardFrameStyle.snow.emoji));
    await t.pumpAndSettle();
    expect(find.text('style:snow'), findsOneWidget);
  });
}
