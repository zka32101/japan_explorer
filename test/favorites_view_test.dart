import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/models/curation.dart';
import 'package:japan_explorer/providers/favorites_provider.dart';
import 'package:japan_explorer/utils/favorites_view.dart';
import 'package:japan_explorer/utils/trip_planner.dart';

Curation _c(String id, String category, String prefecture, String city) =>
    Curation(
      id: id,
      title: id,
      titleJa: id,
      description: '',
      descriptionJa: '',
      category: category,
      prefecture: prefecture,
      city: city,
      imageUrls: const [],
      location: const GeoPoint(35, 135),
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
  // Saved oldest first.
  final a = _c('a', 'shrine', 'Tokyo', 'Shibuya');
  final b = _c('b', 'food', 'Kyoto', 'Gion');
  final c = _c('c', 'shrine', 'Kyoto', 'Arashiyama');
  final saved = [a, b, c];

  test('newest first reverses the saved order', () {
    expect(filterAndSortFavorites(saved).map((x) => x.id), ['c', 'b', 'a']);
  });

  test('area sort groups by prefecture then city', () {
    expect(
      filterAndSortFavorites(saved, sort: FavoriteSort.area).map((x) => x.id),
      ['c', 'b', 'a'], // Kyoto/Arashiyama, Kyoto/Gion, Tokyo/Shibuya
    );
  });

  test('category filter keeps only that category', () {
    expect(
      filterAndSortFavorites(saved, category: 'shrine').map((x) => x.id),
      ['c', 'a'],
    );
    expect(filterAndSortFavorites(saved, category: 'nature'), isEmpty);
  });

  test('categoriesPresent follows the app category order', () {
    expect(categoriesPresent(saved), ['shrine', 'food']);
  });

  test('notes are carried into plan spots and blanks are dropped', () {
    expect(planSpotFromCuration(a, note: '  early  ').note, 'early');
    expect(planSpotFromCuration(a, note: '   ').note, isNull);
    final spots = arrangeByRoute([a, b], notes: {'a': 'book ahead'});
    expect(spots.firstWhere((s) => s.curationId == 'a').note, 'book ahead');
    expect(spots.firstWhere((s) => s.curationId == 'b').note, isNull);
  });
}
