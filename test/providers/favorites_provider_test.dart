import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/models/curation.dart';
import 'package:japan_explorer/providers/favorites_provider.dart';

Curation _curation({List<String> images = const []}) => Curation(
      id: 'c1',
      title: 'Fushimi Inari',
      titleJa: '伏見稲荷大社',
      description: '',
      descriptionJa: '',
      category: 'temple',
      prefecture: 'Kyoto',
      city: 'Kyoto',
      imageUrls: images,
      location: const GeoPoint(34.97, 135.77),
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
  test('planSpotFromCuration uses the first image and the given order', () {
    final spot =
        planSpotFromCuration(_curation(images: ['a.jpg', 'b.jpg']), order: 3);
    expect(spot.curationId, 'c1');
    expect(spot.curationTitle, 'Fushimi Inari');
    expect(spot.imageUrl, 'a.jpg');
    expect(spot.order, 3);
  });

  test('planSpotFromCuration tolerates a spot without images', () {
    expect(planSpotFromCuration(_curation()).imageUrl, isNull);
  });
}
