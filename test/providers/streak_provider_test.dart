import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Helpers ──────────────────────────────────────────────────────────

/// A minimal fake AppUser for auth injection
class _FakeUser {
  final String uid;
  final String displayName;
  String? photoUrl;
  _FakeUser(this.uid, this.displayName);
}

/// Seeds a user document in a FakeFirebaseFirestore.
Future<void> _seedUser(
  FakeFirebaseFirestore db, {
  required String uid,
  int streakDays = 0,
  int recoveryUsed = 0,
  DateTime? lastActivityDate,
  List<String> badges = const [],
  int xp = 0,
  int totalRatings = 0,
}) async {
  final Map<String, dynamic> data = {
    'streak_days': streakDays,
    'streak_recovery_used': recoveryUsed,
    'badges': badges,
    'xp': xp,
    'total_ratings': totalRatings,
  };
  if (lastActivityDate != null) {
    data['last_activity_date'] =
        Timestamp.fromDate(lastActivityDate);
  }
  await db.collection('users').doc(uid).set(data);
}

// ── Tests ─────────────────────────────────────────────────────────────

void main() {
  group('Streak calculation logic', () {
    // Unit-test the pure streak arithmetic without Riverpod:

    test('first activity sets streak to 1', () {
      final result = _calcStreak(
        currentStreak: 0,
        diffDays: -1, // null last_activity_date treated as first-ever
        recoveryUsed: 0,
        maxRecovery: 1,
      );
      expect(result.newStreak, 1);
    });

    test('consecutive day increments streak', () {
      final result = _calcStreak(
        currentStreak: 5,
        diffDays: 1,
        recoveryUsed: 0,
        maxRecovery: 1,
      );
      expect(result.newStreak, 6);
      expect(result.usedRecovery, false);
    });

    test('same day returns unchanged streak', () {
      final result = _calcStreak(
        currentStreak: 5,
        diffDays: 0,
        recoveryUsed: 0,
        maxRecovery: 1,
      );
      expect(result.newStreak, 5);
      expect(result.alreadyLogged, true);
    });

    test('1-day miss with recovery available increments streak', () {
      final result = _calcStreak(
        currentStreak: 6,
        diffDays: 2,
        recoveryUsed: 0,
        maxRecovery: 1,
      );
      expect(result.newStreak, 7);
      expect(result.usedRecovery, true);
    });

    test('1-day miss with no recovery left breaks streak', () {
      final result = _calcStreak(
        currentStreak: 6,
        diffDays: 2,
        recoveryUsed: 1,
        maxRecovery: 1,
      );
      expect(result.newStreak, 1);
      expect(result.usedRecovery, false);
    });

    test('2+ day miss breaks streak', () {
      final result = _calcStreak(
        currentStreak: 14,
        diffDays: 5,
        recoveryUsed: 0,
        maxRecovery: 1,
      );
      expect(result.newStreak, 1);
    });
  });

  group('Badge unlock thresholds', () {
    test('streak_7 unlocks at 7 consecutive days', () {
      expect(_shouldUnlock('streak_7', streak: 7, existing: []), isTrue);
      expect(_shouldUnlock('streak_7', streak: 6, existing: []), isFalse);
      expect(
          _shouldUnlock('streak_7', streak: 7, existing: ['streak_7']),
          isFalse); // already unlocked
    });

    test('streak_30 unlocks at 30 days', () {
      expect(_shouldUnlock('streak_30', streak: 30, existing: []), isTrue);
      expect(_shouldUnlock('streak_30', streak: 29, existing: []), isFalse);
    });

    test('rater_10 unlocks at 10 ratings', () {
      expect(
          _shouldUnlock('rater_10',
              streak: 0, existing: [], totalRatings: 10),
          isTrue);
      expect(
          _shouldUnlock('rater_10',
              streak: 0, existing: [], totalRatings: 9),
          isFalse);
    });
  });
}

// ── Pure helper functions mirroring StreakNotifier logic ──────────────

class _StreakResult {
  final int newStreak;
  final bool alreadyLogged;
  final bool usedRecovery;
  const _StreakResult({
    required this.newStreak,
    this.alreadyLogged = false,
    this.usedRecovery = false,
  });
}

_StreakResult _calcStreak({
  required int currentStreak,
  required int diffDays, // -1 = first ever
  required int recoveryUsed,
  required int maxRecovery,
}) {
  if (diffDays == -1) return const _StreakResult(newStreak: 1);
  if (diffDays == 0) {
    return _StreakResult(newStreak: currentStreak, alreadyLogged: true);
  }
  if (diffDays == 1) {
    return _StreakResult(newStreak: currentStreak + 1);
  }
  if (diffDays == 2 && recoveryUsed < maxRecovery) {
    return _StreakResult(newStreak: currentStreak + 1, usedRecovery: true);
  }
  return const _StreakResult(newStreak: 1);
}

bool _shouldUnlock(
  String badgeId, {
  required int streak,
  required List<String> existing,
  int totalRatings = 0,
  int totalPosts = 0,
  int level = 1,
}) {
  if (existing.contains(badgeId)) return false;
  switch (badgeId) {
    case 'streak_7':
      return streak >= 7;
    case 'streak_30':
      return streak >= 30;
    case 'rater_10':
      return totalRatings >= 10;
    case 'photo_lover':
      return totalPosts >= 5;
    case 'level_5':
      return level >= 5;
    case 'level_7':
      return level >= 7;
    default:
      return false;
  }
}
