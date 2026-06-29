import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

// ── Streak notifier ──────────────────────────────────────────────────

class StreakNotifier extends StateNotifier<AsyncValue<int>> {
  final Ref _ref;
  StreakNotifier(this._ref) : super(const AsyncData(0));

  /// Called on app open — updates streak counter and unlocks badges.
  Future<void> checkAndUpdateStreak() async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(appUserProvider).valueOrNull;
      if (user == null) {
        state = const AsyncData(0);
        return;
      }

      final docRef = FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(user.uid);

      final doc = await docRef.get();
      if (!doc.exists) {
        state = const AsyncData(0);
        return;
      }

      final data = doc.data()!;
      final lastTs = data['last_active_date'] as Timestamp?;
      final currentStreak = (data['streak_days'] ?? 0) as int;
      final recoveryUsed = (data['streak_recovery_used'] ?? 0) as int;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (lastTs == null) {
        // First ever activity
        await docRef.update({
          'streak_days': 1,
          'last_active_date': Timestamp.fromDate(today),
        });
        state = const AsyncData(1);
        await _checkBadgeUnlocks(docRef, data, newStreak: 1);
        return;
      }

      final lastDate = lastTs.toDate();
      final lastDay =
          DateTime(lastDate.year, lastDate.month, lastDate.day);
      final diff = today.difference(lastDay).inDays;

      if (diff == 0) {
        // Already logged today — no update needed
        state = AsyncData(currentStreak);
        return;
      }

      final Map<String, dynamic> updates = {
        'last_active_date': Timestamp.fromDate(today),
      };

      int newStreak;
      if (diff == 1) {
        // Consecutive day
        newStreak = currentStreak + 1;
        updates['streak_days'] = newStreak;
      } else if (diff == 2 &&
          recoveryUsed < AppConstants.streakRecoveryPerMonth) {
        // Streak recovery (1 miss per month allowed)
        newStreak = currentStreak + 1;
        updates['streak_days'] = newStreak;
        updates['streak_recovery_used'] = recoveryUsed + 1;
      } else {
        // Streak broken
        newStreak = 1;
        updates['streak_days'] = 1;
        // Reset recovery allowance at new month
        if (today.month != lastDay.month) {
          updates['streak_recovery_used'] = 0;
        }
      }

      await docRef.update(updates);
      state = AsyncData(newStreak);

      // Re-read doc for badge checks
      final updated = await docRef.get();
      await _checkBadgeUnlocks(docRef, updated.data()!, newStreak: newStreak);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Checks all badge conditions and unlocks newly eligible badges.
  Future<void> _checkBadgeUnlocks(
    DocumentReference docRef,
    Map<String, dynamic> data, {
    required int newStreak,
  }) async {
    final badges = List<String>.from(data['badges'] ?? []);
    final xp = (data['xp'] ?? 0) as int;
    final totalRatings = (data['total_ratings'] ?? 0) as int;
    final totalPosts = (data['total_posts'] ?? 0) as int;
    final level = (data['level'] ?? 1) as int;

    final toUnlock = <String>[];
    var xpGain = 0;

    void tryUnlock(String id, bool condition, int bonusXp) {
      if (condition && !badges.contains(id)) {
        toUnlock.add(id);
        xpGain += bonusXp;
      }
    }

    tryUnlock('streak_7', newStreak >= 7, AppConstants.xpStreakWeek);
    tryUnlock('streak_30', newStreak >= 30, AppConstants.xpStreakWeek * 4);
    tryUnlock('rater_10', totalRatings >= 10, AppConstants.xpReviewPost * 5);
    tryUnlock('photo_lover', totalPosts >= 5, AppConstants.xpPhotoUpload * 3);
    tryUnlock('level_5', level >= 5, AppConstants.xpLevelUpBonus);
    tryUnlock('level_7', level >= 7, AppConstants.xpLevelUpBonus);

    if (toUnlock.isNotEmpty) {
      await docRef.update({
        'badges': [...badges, ...toUnlock],
        'xp': xp + xpGain,
        'new_badges': toUnlock, // Ephemeral — consumed by UI for animation
      });
    }
  }
}

final streakNotifierProvider =
    StateNotifierProvider<StreakNotifier, AsyncValue<int>>(
  (ref) => StreakNotifier(ref),
);
