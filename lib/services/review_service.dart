import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Engagement-based in-app review prompt.
///
/// Scoring rules (call [addEngagement] with the appropriate points):
///   - Curation detail viewed:  1 pt
///   - Audio guide played:      5 pt
///   - Plan generated:          5 pt
///   - Challenge completed:     3 pt
///   - Post created:            3 pt
///
/// Review is requested once the engagement score crosses a threshold
/// AND at least 30 days have passed since the last prompt.
class ReviewService {
  ReviewService._();

  static const _kScoreKey = 'review_engagement_score';
  static const _kLastShownKey = 'review_last_shown_ms';
  static const _kMinDaysBetween = 30;

  // Score thresholds at which we prompt (once each)
  static const _kThresholds = {10, 30, 100};

  final _inAppReview = InAppReview.instance;

  // ── Points constants ─────────────────────────────────────────────────────

  static const ptDetailViewed = 1;
  static const ptAudioGuidePlayed = 5;
  static const ptPlanGenerated = 5;
  static const ptChallengeCompleted = 3;
  static const ptPostCreated = 3;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Increment the engagement score and prompt if a threshold is hit.
  Future<void> addEngagement(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_kScoreKey) ?? 0;
    final updated = current + points;
    await prefs.setInt(_kScoreKey, updated);

    // Check if we crossed a threshold
    final crossed = _kThresholds.where((t) => current < t && updated >= t);
    if (crossed.isNotEmpty) {
      await _maybeRequestReview(prefs);
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _maybeRequestReview(SharedPreferences prefs) async {
    final lastMs = prefs.getInt(_kLastShownKey) ?? 0;
    final daysSince = lastMs == 0
        ? double.infinity
        : DateTime.now()
                .difference(
                    DateTime.fromMillisecondsSinceEpoch(lastMs))
                .inDays
                .toDouble();

    if (daysSince < _kMinDaysBetween) return;

    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await prefs.setInt(
            _kLastShownKey, DateTime.now().millisecondsSinceEpoch);
      }
    } catch (_) {
      // Non-fatal — never crash because of a review prompt
    }
  }
}

final reviewService = ReviewService._();
