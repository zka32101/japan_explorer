import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/curation.dart';
import '../models/rating.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/firestore_instance.dart';

// ── XP update result ─────────────────────────────────────────────────────────

class XpUpdateResult {
  final int newXp;
  final int newLevel;
  final bool leveledUp;
  final List<String> newBadgeIds;

  const XpUpdateResult({
    required this.newXp,
    required this.newLevel,
    required this.leveledUp,
    required this.newBadgeIds,
  });

  bool get hasBadges => newBadgeIds.isNotEmpty;
}

// ── Level thresholds (matches AppUser.levelXpRequired) ───────────────────────
int computeUserLevel(int xp) {
  if (xp >= 8000) return 10;
  if (xp >= 6000) return 9;
  if (xp >= 5000) return 8;
  if (xp >= 4000) return 7;
  if (xp >= 3000) return 6;
  if (xp >= 2500) return 5;
  if (xp >= 1500) return 4;
  if (xp >= 1000) return 3;
  if (xp >= 500)  return 2;
  return 1;
}

class FirebaseService {
  final FirebaseFirestore _db = db;
  final _logger = Logger();

  // Curations

  /// Simple list fetch (used by FutureProviders).
  Future<List<Curation>> getCurations({
    String? category,
    int limit = AppConstants.pageSize,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = _db
          .collection(FirestoreCollections.curations)
          .where('is_active', isEqualTo: true)
          .orderBy('overall_rank')
          .limit(limit);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Curation.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.e('Error fetching curations', error: e);
      rethrow;
    }
  }

  /// Paginated fetch — returns items + last DocumentSnapshot cursor.
  Future<(List<Curation>, DocumentSnapshot?)> getCurationsPage({
    String? category,
    int limit = AppConstants.pageSize,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = _db
          .collection(FirestoreCollections.curations)
          .where('is_active', isEqualTo: true)
          .orderBy('overall_rank')
          .limit(limit);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final items =
          snapshot.docs.map((d) => Curation.fromFirestore(d)).toList();
      final cursor =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      return (items, cursor);
    } catch (e) {
      _logger.e('Error fetching curations page', error: e);
      rethrow;
    }
  }

  Future<Curation?> getCuration(String id) async {
    try {
      final doc = await _db
          .collection(FirestoreCollections.curations)
          .doc(id)
          .get();
      if (!doc.exists) return null;
      return Curation.fromFirestore(doc);
    } catch (e) {
      _logger.e('Error fetching curation $id', error: e);
      rethrow;
    }
  }

  Future<List<Curation>> searchCurations(String query) async {
    try {
      final snapshot = await _db
          .collection(FirestoreCollections.curations)
          .where('is_active', isEqualTo: true)
          .where('tags', arrayContains: query.toLowerCase())
          .limit(AppConstants.pageSize)
          .get();
      return snapshot.docs.map((doc) => Curation.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.e('Error searching curations', error: e);
      rethrow;
    }
  }

  // Ratings
  Future<void> submitRating({
    required String curationId,
    required String userId,
    required double wantToGo,
    required double recommend,
  }) async {
    try {
      final ratingId = '${userId}_$curationId';
      await _db
          .collection(FirestoreCollections.ratings)
          .doc(ratingId)
          .set({
        'curation_id': curationId,
        'user_id': userId,
        'want_to_go': wantToGo,
        'recommend': recommend,
        'is_outlier': false,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _logger.e('Error submitting rating', error: e);
      rethrow;
    }
  }

  Future<Rating?> getUserRating(String curationId, String userId) async {
    try {
      final doc = await _db
          .collection(FirestoreCollections.ratings)
          .doc('${userId}_$curationId')
          .get();
      if (!doc.exists) return null;
      return Rating.fromFirestore(doc);
    } catch (e) {
      _logger.e('Error fetching user rating', error: e);
      rethrow;
    }
  }

  // Plans
  Future<List<Plan>> getUserPlans(String userId) async {
    try {
      final snapshot = await _db
          .collection(FirestoreCollections.plans)
          .where('user_id', isEqualTo: userId)
          .orderBy('updated_at', descending: true)
          .get();
      return snapshot.docs.map((doc) => Plan.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.e('Error fetching plans', error: e);
      rethrow;
    }
  }

  Future<String> createPlan(Plan plan) async {
    try {
      final docRef = await _db
          .collection(FirestoreCollections.plans)
          .add(plan.toFirestore());
      return docRef.id;
    } catch (e) {
      _logger.e('Error creating plan', error: e);
      rethrow;
    }
  }

  Future<void> updatePlan(Plan plan) async {
    try {
      await _db
          .collection(FirestoreCollections.plans)
          .doc(plan.id)
          .update(plan.toFirestore());
    } catch (e) {
      _logger.e('Error updating plan', error: e);
      rethrow;
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      await _db.collection(FirestoreCollections.plans).doc(planId).delete();
    } catch (e) {
      _logger.e('Error deleting plan', error: e);
      rethrow;
    }
  }

  // User
  Future<void> updateUserPreferences(
      String userId, List<String> categories) async {
    await _db.collection(FirestoreCollections.users).doc(userId).update({
      'preferred_categories': categories,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Awards XP atomically. Recomputes level and unlocks level-based badges.
  /// Returns [XpUpdateResult] describing what changed.
  Future<XpUpdateResult> updateUserXP(String userId, int xpToAdd) async {
    try {
      final ref = _db.collection(FirestoreCollections.users).doc(userId);
      return await _db.runTransaction<XpUpdateResult>((txn) async {
        final snap = await txn.get(ref);
        if (!snap.exists) {
          return XpUpdateResult(
            newXp: xpToAdd,
            newLevel: 1,
            leveledUp: false,
            newBadgeIds: [],
          );
        }
        final data = snap.data()!;
        final oldXp = (data['xp'] as num?)?.toInt() ?? 0;
        final oldLevel = (data['level'] as num?)?.toInt() ?? 1;
        final existingBadges =
            List<String>.from(data['badges'] as List? ?? []);

        final newXp = oldXp + xpToAdd;
        final newLevel = computeUserLevel(newXp);
        final leveledUp = newLevel > oldLevel;

        // Unlock level-based badges automatically
        final newBadgeIds = <String>[];
        if (newLevel >= 5 && !existingBadges.contains('level_5')) {
          newBadgeIds.add('level_5');
        }
        if (newLevel >= 7 && !existingBadges.contains('level_7')) {
          newBadgeIds.add('level_7');
        }
        if (newLevel >= 10 && !existingBadges.contains('japan_master')) {
          newBadgeIds.add('japan_master');
        }

        final update = <String, Object>{
          'xp': newXp,
          'updated_at': FieldValue.serverTimestamp(),
        };
        if (leveledUp) update['level'] = newLevel;
        if (newBadgeIds.isNotEmpty) {
          update['badges'] = FieldValue.arrayUnion(newBadgeIds);
        }

        txn.update(ref, update);

        return XpUpdateResult(
          newXp: newXp,
          newLevel: newLevel,
          leveledUp: leveledUp,
          newBadgeIds: newBadgeIds,
        );
      });
    } catch (e) {
      _logger.e('Error updating XP for $userId', error: e);
      // Fall back to simple increment so XP is never lost
      await _db.collection(FirestoreCollections.users).doc(userId).update({
        'xp': FieldValue.increment(xpToAdd),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return XpUpdateResult(
        newXp: -1, newLevel: -1, leveledUp: false, newBadgeIds: [],
      );
    }
  }

  /// Awards a badge only if the user doesn't already have it.
  /// Returns the badge ID if newly awarded, empty list otherwise.
  Future<List<String>> awardBadgeIfNew(
      String userId, String badgeId) async {
    try {
      final ref = _db.collection(FirestoreCollections.users).doc(userId);
      return await _db.runTransaction<List<String>>((txn) async {
        final snap = await txn.get(ref);
        if (!snap.exists) return [];
        final existing =
            List<String>.from(snap.data()?['badges'] as List? ?? []);
        if (existing.contains(badgeId)) return [];
        txn.update(ref, {
          'badges': FieldValue.arrayUnion([badgeId]),
          'updated_at': FieldValue.serverTimestamp(),
        });
        return [badgeId];
      });
    } catch (e) {
      _logger.e('Error awarding badge $badgeId', error: e);
      return [];
    }
  }

  Stream<AppUser> streamUser(String userId) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .snapshots()
        .map((doc) => AppUser.fromFirestore(doc));
  }
}
