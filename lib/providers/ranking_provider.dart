import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/curation.dart';
import '../services/firebase_service.dart';
import '../utils/firestore_instance.dart';

enum RankingFilter { overall, weekly, category }

final rankingFilterProvider = StateProvider<RankingFilter>((ref) => RankingFilter.overall);
final rankingCategoryProvider = StateProvider<String?>((ref) => null);

final rankingProvider = FutureProvider.family<List<Curation>, RankingFilter>(
  (ref, filter) async {
    final category = ref.watch(rankingCategoryProvider);

    Query query = db
        .collection('curations')
        .where('is_active', isEqualTo: true)
        .limit(20);

    switch (filter) {
      case RankingFilter.overall:
        query = query.orderBy('overall_rank');
      case RankingFilter.weekly:
        query = query.orderBy('trending_score', descending: true);
      case RankingFilter.category:
        if (category != null) {
          query = query
              .where('category', isEqualTo: category)
              .orderBy('category_rank');
        } else {
          query = query.orderBy('overall_rank');
        }
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Curation.fromFirestore(doc)).toList();
  },
);
