import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/models/curation.dart';
import 'package:japan_explorer/utils/trip_planner.dart';

Curation _c(String id, double lat, double lng) => Curation(
      id: id,
      title: id,
      titleJa: id,
      description: '',
      descriptionJa: '',
      category: 'temple',
      prefecture: '',
      city: '',
      imageUrls: const [],
      location: GeoPoint(lat, lng),
      averageWantToGo: 0,
      averageRecommend: 0,
      totalRatings: 0,
      overallRank: 0,
      categoryRank: 0,
      practicalInfo: const {},
      tags: const [],
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  // Tokyo area (139.7), Kyoto area (135.7), Osaka (135.5).
  final tokyo1 = _c('tokyo1', 35.68, 139.76);
  final tokyo2 = _c('tokyo2', 35.66, 139.70);
  final kyoto = _c('kyoto', 35.01, 135.77);
  final osaka = _c('osaka', 34.69, 135.50);

  test('distanceKm is roughly right (Tokyo to Osaka about 400 km)', () {
    final d = distanceKm(35.68, 139.76, 34.69, 135.50);
    expect(d, inInclusiveRange(380, 420));
    expect(distanceKm(35, 135, 35, 135), 0);
  });

  test('one day: nearest-neighbour order from the west, no day numbers', () {
    final spots = arrangeByRoute([tokyo1, kyoto, tokyo2, osaka]);
    expect(spots.map((s) => s.curationId).toList(),
        ['osaka', 'kyoto', 'tokyo2', 'tokyo1']);
    expect(spots.map((s) => s.order).toList(), [0, 1, 2, 3]);
    expect(spots.every((s) => s.dayNumber == null), isTrue);
  });

  test('two days keep each area together', () {
    final spots = arrangeByRoute([tokyo1, kyoto, tokyo2, osaka], days: 2);
    expect(spots.where((s) => s.dayNumber == 1).map((s) => s.curationId),
        ['osaka', 'kyoto']);
    expect(spots.where((s) => s.dayNumber == 2).map((s) => s.curationId),
        ['tokyo2', 'tokyo1']);
  });

  test('uneven split gives the first days one more; days are capped', () {
    final three = arrangeByRoute([tokyo1, kyoto, osaka], days: 2);
    expect(three.map((s) => s.dayNumber).toList(), [1, 1, 2]);
    final capped = arrangeByRoute([tokyo1, kyoto], days: 5);
    expect(capped.map((s) => s.dayNumber).toList(), [1, 2]);
  });

  test('empty input gives an empty plan', () {
    expect(arrangeByRoute([], days: 3), isEmpty);
  });
}
