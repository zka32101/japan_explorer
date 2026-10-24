import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/widgets/theme/brand_scaffold.dart';

void main() {
  testWidgets('shows title and body, no back button at the root', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: BrandScaffold(title: 'Rankings', body: Text('content')),
    ));
    expect(find.text('Rankings'), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('back button pops a pushed route', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const BrandScaffold(title: 'Sub', body: Text('b')),
          )),
          child: const Text('go'),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await t.tap(find.byIcon(Icons.arrow_back));
    await t.pumpAndSettle();
    expect(find.text('Sub'), findsNothing);
  });
}
