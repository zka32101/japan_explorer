import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/culture_content.dart';
import '../utils/firestore_instance.dart';

class RelatedContentParams {
  final String contentId;
  final List<String> tags;
  final String categoryId;
  final List<String> seeAlso;

  const RelatedContentParams({
    required this.contentId,
    required this.tags,
    required this.categoryId,
    this.seeAlso = const [],
  });

  @override
  bool operator ==(Object other) =>
      other is RelatedContentParams &&
      other.contentId == contentId &&
      other.categoryId == categoryId &&
      other.tags.join(',') == tags.join(',') &&
      other.seeAlso.join(',') == seeAlso.join(',');

  @override
  int get hashCode => Object.hash(contentId, categoryId, tags.join(','), seeAlso.join(','));
}

final cultureContentProvider = FutureProvider.family<
    List<CultureContent>,
    String>((ref, categoryId) async {
  final snapshot = await db
      .collection('culture_content')
      .where('categoryId', isEqualTo: categoryId)
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => CultureContent.fromMap({
        ...doc.data(),
        'id': doc.id,
      }))
      .toList();
});

final allCultureCategoriesProvider = FutureProvider<
    List<CultureCategory>>((ref) async {
  return [
    CultureCategory(
      id: 'culture',
      name: 'Culture',
      emoji: '🏮',
      description: 'Tea ceremony, martial arts, crafts, and traditions',
      tags: ['ceremony', 'tradition', 'art'],
    ),
    CultureCategory(
      id: 'food',
      name: 'Food Culture',
      emoji: '🍱',
      description: 'Cuisine, ingredients, cooking methods, and dining etiquette',
      tags: ['food', 'cuisine', 'cooking'],
    ),
    CultureCategory(
      id: 'region',
      name: 'Regional Stories',
      emoji: '🗾',
      description: 'History, specialties, and unique cultures of each prefecture',
      tags: ['region', 'prefecture', 'history'],
    ),
    CultureCategory(
      id: 'art',
      name: 'Art & Design',
      emoji: '🎨',
      description: 'Aesthetics, colors, motifs, and design philosophy',
      tags: ['art', 'design', 'beauty'],
    ),
    CultureCategory(
      id: 'language',
      name: 'Language & Expression',
      emoji: '📖',
      description: 'Phrases, kanji origins, honorifics, and linguistic depth',
      tags: ['language', 'phrase', 'kanji'],
    ),
  ];
});

final cultureCategoryProvider = FutureProvider.family<
    CultureCategory?,
    String>((ref, categoryId) async {
  final categories = await ref.watch(allCultureCategoriesProvider.future);
  return categories.firstWhere(
    (cat) => cat.id == categoryId,
    orElse: () => categories.first,
  );
});

final cultureContentSearchProvider = FutureProvider.family<
    List<CultureContent>,
    String>((ref, searchTerm) async {
  final snapshot = await db
      .collection('culture_content')
      .where('tags', arrayContains: searchTerm.toLowerCase())
      .limit(20)
      .get();

  return snapshot.docs
      .map((doc) => CultureContent.fromMap({
        ...doc.data(),
        'id': doc.id,
      }))
      .toList();
});

final relatedCultureContentProvider = FutureProvider.family<
    List<CultureContent>,
    RelatedContentParams>((ref, params) async {
  final List<CultureContent> results = [];

  // Priority 1: explicit seeAlso IDs
  if (params.seeAlso.isNotEmpty) {
    final futures = params.seeAlso
        .map((id) => db.collection('culture_content').doc(id).get());
    final docs = await Future.wait(futures);
    for (final doc in docs) {
      if (doc.exists) {
        results.add(CultureContent.fromMap({...doc.data()!, 'id': doc.id}));
      }
    }
    if (results.length >= 4) return results.take(4).toList();
  }

  // Priority 2: tag-based fill
  if (params.tags.isEmpty) return results;
  final queryTags = params.tags.take(10).toList();
  final snapshot = await db
      .collection('culture_content')
      .where('tags', arrayContainsAny: queryTags)
      .limit(20)
      .get();

  final existing = results.map((e) => e.id).toSet()..add(params.contentId);
  final tagResults = snapshot.docs
      .map((doc) => CultureContent.fromMap({...doc.data(), 'id': doc.id}))
      .where((item) => !existing.contains(item.id))
      .toList();

  tagResults.sort((a, b) {
    final scoreA = a.tags.where(params.tags.contains).length +
        (a.categoryId == params.categoryId ? 2 : 0);
    final scoreB = b.tags.where(params.tags.contains).length +
        (b.categoryId == params.categoryId ? 2 : 0);
    return scoreB.compareTo(scoreA);
  });

  results.addAll(tagResults);
  return results.take(4).toList();
});
