import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/models/rating.dart';
import 'package:japan_explorer/services/share_service.dart';

PlanSpot _spot(String title, int order, {int? day, String? note}) => PlanSpot(
      curationId: 'c$order',
      curationTitle: title,
      order: order,
      dayNumber: day,
      note: note,
    );

Plan _plan({String? description, DateTime? start, DateTime? end}) => Plan(
      id: 'p',
      userId: 'u',
      title: 'Kyoto trip',
      description: description,
      spots: const [],
      startDate: start,
      endDate: end,
      isPublic: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('groups spots by day and numbers them per day', () {
    final text = ShareService.planShareText(
      _plan(start: DateTime(2026, 4, 3), end: DateTime(2026, 4, 5)),
      [
        _spot('Fushimi Inari', 0, day: 1),
        _spot('Kiyomizu-dera', 1, day: 1, note: 'go early'),
        _spot('Arashiyama', 2, day: 2),
      ],
    );
    expect(text, contains('🗾 Kyoto trip'));
    expect(text, contains('📅 2026-04-03 – 2026-04-05'));
    expect(text, contains('Day 1\n1. Fushimi Inari\n2. Kiyomizu-dera — go early\n'));
    expect(text, contains('Day 2\n1. Arashiyama\n'));
  });

  test('without days it is a single numbered list, description is optional', () {
    final text = ShareService.planShareText(
      _plan(description: 'Temples & food'),
      [_spot('A', 0), _spot('B', 1)],
    );
    expect(text, contains('Temples & food\n'));
    expect(text, isNot(contains('Day ')));
    expect(text, contains('1. A\n2. B\n'));
    expect(text, isNot(contains('📅')));
  });

  test('ends with the app name and store link', () {
    final text = ShareService.planShareText(_plan(), [_spot('A', 0)]);
    expect(text, contains('Made with Showglobe Japan'));
    expect(text, contains('play.google.com'));
  });
}
