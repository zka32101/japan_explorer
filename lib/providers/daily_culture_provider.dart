import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/culture_content.dart';
import '../services/culture_content_seeder.dart';
import '../utils/constants.dart';
import '../utils/firestore_instance.dart';
import 'auth_provider.dart';

// ── Hive box name ─────────────────────────────────────────────────────────────
const _kCultureReadsBox = 'culture_reads';
const _kReadIdsKey = 'read_ids';
const _kLastDailyKey = 'last_daily_date';

// ── Today's culture content (deterministic by day-of-year) ───────────────────

final dailyCultureProvider = Provider<CultureContent>((ref) {
  final all = CultureContentSeeder.allContent;
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  return all[dayOfYear % all.length];
});

// ── Read tracking notifier ────────────────────────────────────────────────────

class CultureReadNotifier extends StateNotifier<Set<String>> {
  final Ref _ref;
  Box<String>? _box;

  CultureReadNotifier(this._ref) : super({}) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<String>(_kCultureReadsBox);
    final raw = _box!.get(_kReadIdsKey);
    if (raw != null) {
      final list = (json.decode(raw) as List).cast<String>();
      state = list.toSet();
    }
  }

  bool get hasReadToday {
    final box = _box;
    if (box == null) return false;
    final lastDate = box.get(_kLastDailyKey);
    final today = _todayStr();
    return lastDate == today;
  }

  bool isRead(String id) => state.contains(id);

  Future<void> markRead(String id) async {
    if (state.contains(id)) return;
    final updated = {...state, id};
    state = updated;
    await _box?.put(_kReadIdsKey, json.encode(updated.toList()));

    // Track XP in Firestore
    final user = _ref.read(appUserProvider).valueOrNull;
    if (user != null) {
      try {
        await db.collection(FirestoreCollections.users).doc(user.uid).update({
          'xp': user.xp + AppConstants.xpCultureRead,
          'total_culture_read': updated.length,
        });
        // Badge unlocks
        await _checkBadges(user.uid, updated.length, user.xp + AppConstants.xpCultureRead);
      } catch (_) {}
    }
  }

  Future<void> markDailyRead(String id) async {
    await markRead(id);
    final today = _todayStr();
    await _box?.put(_kLastDailyKey, today);
    // Notify state change to re-render card
    state = {...state};
  }

  int get readCount => state.length;

  int countForCategory(String categoryId) {
    final all = CultureContentSeeder.allContent;
    return all
        .where((c) => c.categoryId == categoryId && state.contains(c.id))
        .length;
  }

  int totalForCategory(String categoryId) {
    return CultureContentSeeder.allContent
        .where((c) => c.categoryId == categoryId)
        .length;
  }

  List<CultureContent> get recentlyRead {
    final all = CultureContentSeeder.allContent;
    // Return last 10 read items (in order they appear in seeder)
    return all.where((c) => state.contains(c.id)).toList().reversed.take(10).toList();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _checkBadges(String uid, int totalRead, int newXp) async {
    try {
      final doc = await db.collection(FirestoreCollections.users).doc(uid).get();
      final data = doc.data()!;
      final badges = List<String>.from(data['badges'] ?? []);
      final toUnlock = <String>[];
      var xpGain = 0;

      void tryUnlock(String id, bool cond, int bonus) {
        if (cond && !badges.contains(id)) {
          toUnlock.add(id);
          xpGain += bonus;
        }
      }

      tryUnlock(AppConstants.badgeCultureFan, totalRead >= 10, 100);
      tryUnlock(AppConstants.badgeCultureScholar, totalRead >= 50, 300);
      tryUnlock(AppConstants.badgeCultureMaster, totalRead >= 200, 800);

      if (toUnlock.isNotEmpty) {
        await db.collection(FirestoreCollections.users).doc(uid).update({
          'badges': [...badges, ...toUnlock],
          'xp': newXp + xpGain,
          'new_badges': toUnlock,
        });
      }
    } catch (_) {}
  }
}

final cultureReadProvider =
    StateNotifierProvider<CultureReadNotifier, Set<String>>(
  (ref) => CultureReadNotifier(ref),
);

// ── Convenience bool: has user read today's daily culture ────────────────────

final dailyCultureReadTodayProvider = Provider<bool>((ref) {
  ref.watch(cultureReadProvider); // rebuild on any read change
  final notifier = ref.read(cultureReadProvider.notifier);
  return notifier.hasReadToday;
});
