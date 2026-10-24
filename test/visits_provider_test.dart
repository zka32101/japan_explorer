import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/models/curation.dart';
import 'package:japan_explorer/models/journal_entry.dart';
import 'package:japan_explorer/providers/visits_provider.dart';

Curation _spot(String id, String prefecture, {List<String> images = const []}) =>
    Curation(
      id: id,
      title: id,
      titleJa: id,
      description: '',
      descriptionJa: '',
      category: 'temple',
      prefecture: prefecture,
      city: '',
      imageUrls: images,
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

JournalEntry _entry(String curationId, DateTime at, {String image = ''}) =>
    JournalEntry(
      id: '$curationId-${at.millisecondsSinceEpoch}',
      userId: 'u',
      curationId: curationId,
      curationTitle: 'Title $curationId',
      content: '',
      imageUrl: image,
      mood: JournalMood.good,
      visitDate: at,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  test('journal entries become visit records with a region and a photo', () {
    final records = buildVisitRecords(
      [
        _entry('a', DateTime(2026, 4, 1), image: 'mine.jpg'),
        _entry('b', DateTime(2026, 5, 2)),
        _entry('c', DateTime(2026, 6, 3)), // spot not found
      ],
      {
        'a': _spot('a', 'Kyoto', images: ['spot-a.jpg']),
        'b': _spot('b', '東京都', images: ['spot-b.jpg']),
      },
    );
    expect(records.map((r) => r.placeId), ['a', 'b', 'c']);
    expect(records.map((r) => r.regionId), ['26', '13', null]);
    // the entry's own photo wins; otherwise the spot's first image
    expect(records.map((r) => r.imageUrl), ['mine.jpg', 'spot-b.jpg', null]);
    expect(records.first.title, 'Title a');
    expect(records.first.visitedAt, DateTime(2026, 4, 1));
  });
}
