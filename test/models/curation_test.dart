import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/models/curation.dart';

void main() {
  group('CurationCategory helpers', () {
    test('emoji returns non-empty string for every known category', () {
      for (final cat in CurationCategory.all) {
        final emoji = CurationCategory.emoji(cat);
        expect(emoji, isNotEmpty, reason: 'No emoji for category: $cat');
      }
    });

    test('label returns non-empty string for every known category', () {
      for (final cat in CurationCategory.all) {
        final label = CurationCategory.label(cat);
        expect(label, isNotEmpty, reason: 'No label for category: $cat');
      }
    });

    test('emoji falls back gracefully for unknown category', () {
      final emoji = CurationCategory.emoji('unknown_cat');
      expect(emoji, isA<String>()); // should not throw
    });
  });

  group('Curation.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('parses all standard fields', () async {
      final ref = await fakeFirestore.collection('curations').add({
        'title': 'Kinkaku-ji',
        'description': 'The Golden Pavilion',
        'category': 'shrine',
        'prefecture': 'Kyoto',
        'city': 'Kyoto',
        'address': '1 Kinkakuji-cho',
        'location': const GeoPoint(35.0394, 135.7292),
        'image_urls': ['https://example.com/img1.jpg'],
        'tags': ['temple', 'zen'],
        'is_active': true,
        'overall_rank': 5,
        'avg_want_to_go': 4.8,
        'avg_recommend': 4.9,
        'total_ratings': 1024,
        'practical_info': {'hours': '9:00–17:00'},
      });

      final doc = await ref.get();
      final curation = Curation.fromFirestore(doc);

      expect(curation.title, 'Kinkaku-ji');
      expect(curation.category, 'shrine');
      expect(curation.prefecture, 'Kyoto');
      expect(curation.overallRank, 5);
      expect(curation.averageWantToGo, closeTo(4.8, 0.01));
      expect(curation.totalRatings, 1024);
      expect(curation.imageUrls, ['https://example.com/img1.jpg']);
      expect(curation.practicalInfo['hours'], '9:00–17:00');
    });

    test('handles missing optional fields gracefully', () async {
      final ref = await fakeFirestore.collection('curations').add({
        'title': 'Minimal Spot',
        'description': '',
        'category': 'nature',
        'prefecture': 'Hokkaido',
        'city': 'Sapporo',
        'address': '',
        'location': const GeoPoint(43.0, 141.0),
        'is_active': true,
      });

      final doc = await ref.get();
      final curation = Curation.fromFirestore(doc);

      expect(curation.imageUrls, isEmpty);
      expect(curation.tags, isEmpty);
      expect(curation.overallRank, 0);
      expect(curation.totalRatings, 0);
      expect(curation.practicalInfo, isEmpty);
    });
  });
}
