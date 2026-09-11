import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cultural_challenge.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';
import 'progress_provider.dart';

const _prefKey = 'daily_challenge_v1';

class ChallengeState {
  final CulturalChallenge challenge;
  final int? selectedIndex;   // null = not answered yet
  final bool isCorrect;
  final bool alreadyAnsweredToday;
  final int? xpEarned;
  // Level-up / badge-unlock feedback (shown once then cleared)
  final bool leveledUp;
  final int? newLevel;
  final List<String> newBadgeIds;

  const ChallengeState({
    required this.challenge,
    this.selectedIndex,
    this.isCorrect = false,
    this.alreadyAnsweredToday = false,
    this.xpEarned,
    this.leveledUp = false,
    this.newLevel,
    this.newBadgeIds = const [],
  });

  bool get isAnswered => selectedIndex != null;

  ChallengeState clearFeedback() => ChallengeState(
        challenge: challenge,
        selectedIndex: selectedIndex,
        isCorrect: isCorrect,
        alreadyAnsweredToday: alreadyAnsweredToday,
        xpEarned: xpEarned,
      );
}

class ChallengeNotifier extends StateNotifier<ChallengeState> {
  final Ref _ref;

  ChallengeNotifier(this._ref)
      : super(ChallengeState(
          challenge: ChallengeBank.getForDate(DateTime.now()),
        )) {
    _loadTodayState();
  }

  Future<void> _loadTodayState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final savedDate = json['date'] as String?;
      final today = _dateKey(DateTime.now());
      if (savedDate != today) return; // stale — yesterday's result

      final answeredIndex = json['selectedIndex'] as int?;
      final correct = json['isCorrect'] as bool? ?? false;
      final xpEarned = json['xpEarned'] as int?;

      if (answeredIndex != null) {
        state = ChallengeState(
          challenge: state.challenge,
          selectedIndex: answeredIndex,
          isCorrect: correct,
          alreadyAnsweredToday: true,
          xpEarned: xpEarned,
        );
      }
    } catch (_) {}
  }

  Future<void> answer(int index) async {
    if (state.isAnswered) return;

    final challenge = state.challenge;
    final correct = index == challenge.correctIndex;
    final xp = correct ? challenge.xpCorrect : challenge.xpAttempt;

    // Optimistically update UI
    state = ChallengeState(
      challenge: challenge,
      selectedIndex: index,
      isCorrect: correct,
      alreadyAnsweredToday: true,
      xpEarned: xp,
    );

    // Persist daily result
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode({
        'date': _dateKey(DateTime.now()),
        'challengeId': challenge.id,
        'selectedIndex': index,
        'isCorrect': correct,
        'xpEarned': xp,
      }),
    );

    // Accumulate category stats (fire-and-forget)
    accumulateChallengeResult(
      category: challenge.category,
      correct: correct,
      xp: xp,
    );

    // Award XP and check for level-up / badge unlocks
    _awardXpAndNotify(xp);
  }

  Future<void> _awardXpAndNotify(int xp) async {
    try {
      final user = _ref.read(appUserProvider).valueOrNull;
      if (user == null) return;
      final result = await _ref
          .read(firebaseServiceProvider)
          .updateUserXP(user.uid, xp);

      if (result.leveledUp || result.hasBadges) {
        state = ChallengeState(
          challenge: state.challenge,
          selectedIndex: state.selectedIndex,
          isCorrect: state.isCorrect,
          alreadyAnsweredToday: state.alreadyAnsweredToday,
          xpEarned: state.xpEarned,
          leveledUp: result.leveledUp,
          newLevel: result.newLevel,
          newBadgeIds: result.newBadgeIds,
        );
      }
    } catch (_) {}
  }

  /// Called by the UI after it has displayed the level-up / badge overlays.
  void clearFeedback() {
    state = state.clearFeedback();
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

final challengeNotifierProvider =
    StateNotifierProvider<ChallengeNotifier, ChallengeState>((ref) {
  return ChallengeNotifier(ref);
});
