import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cultural_challenge.dart';
import '../models/cultural_progress.dart';
import '../models/scan_history.dart';

// SharedPreferences key where challenge_provider accumulates per-category stats.
const challengeProgressKey = 'challenge_progress_v1';

/// Reads accumulated challenge stats and scan history, returns a summary.
final culturalProgressProvider =
    FutureProvider<CulturalProgressSummary>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(challengeProgressKey);

  // Build per-category progress
  final categoryMap = <ChallengeCategory, CategoryProgress>{};
  for (final cat in ChallengeCategory.values) {
    categoryMap[cat] = CategoryProgress(category: cat);
  }

  if (raw != null) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      for (final cat in ChallengeCategory.values) {
        final catJson = json[cat.name] as Map<String, dynamic>?;
        if (catJson != null) {
          categoryMap[cat] = CategoryProgress.fromJson(cat, catJson);
        }
      }
    } catch (_) {}
  }

  // Scan count from local history
  final scans = await scanHistoryRepository.getAll();

  return CulturalProgressSummary(
    categories: categoryMap.values.toList(),
    scanCount: scans.length,
  );
});

/// Accumulate a quiz answer into the persistent per-category stats.
/// Called from ChallengeNotifier after a successful answer.
Future<void> accumulateChallengeResult({
  required ChallengeCategory category,
  required bool correct,
  required int xp,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(challengeProgressKey);

  Map<String, dynamic> json;
  try {
    json = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : {};
  } catch (_) {
    json = {};
  }

  final existing = json[category.name] as Map<String, dynamic>?;
  final prev = existing != null
      ? CategoryProgress.fromJson(category, existing)
      : CategoryProgress(category: category);

  json[category.name] = prev.add(correct: correct, xp: xp).toJson();

  await prefs.setString(challengeProgressKey, jsonEncode(json));
}
