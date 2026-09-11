import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Thin wrapper around FirebaseAnalytics.
/// All log methods are fire-and-forget (errors are silently swallowed).
class AnalyticsService {
  AnalyticsService._();

  final _fa = FirebaseAnalytics.instance;

  // ── Screen tracking ────────────────────────────────────────────────────────

  Future<void> logScreenView(String screenName) async {
    if (kDebugMode) return;
    try {
      await _fa.logScreenView(screenName: screenName);
    } catch (_) {}
  }

  // ── Content events ─────────────────────────────────────────────────────────

  Future<void> logCurationViewed(String id, String category) =>
      _log('curation_viewed', {'curation_id': id, 'category': category});

  Future<void> logSearchPerformed(String query) =>
      _log('search_performed', {'query': query.substring(0, query.length.clamp(0, 36))});

  Future<void> logAudioGuideGenerated(String curationId, String category) =>
      _log('audio_guide_generated', {'curation_id': curationId, 'category': category});

  Future<void> logAudioGuidePlayed(String curationId) =>
      _log('audio_guide_played', {'curation_id': curationId});

  Future<void> logPlanGenerated(int days, int interestsCount) =>
      _log('ai_plan_generated', {'days': days, 'interests_count': interestsCount});

  // ── Gamification events ────────────────────────────────────────────────────

  Future<void> logChallengeCompleted(String challengeId, int xp) =>
      _log('challenge_completed', {'challenge_id': challengeId, 'xp': xp});

  Future<void> logLevelUp(int newLevel) =>
      _log('level_up', {'level': newLevel});

  Future<void> logBadgeEarned(String badgeId) =>
      _log('badge_earned', {'badge_id': badgeId});

  Future<void> logStreakUpdated(int streakDays) =>
      _log('streak_updated', {'streak_days': streakDays});

  // ── Monetization events ────────────────────────────────────────────────────

  Future<void> logPremiumPaywallShown(String source) =>
      _log('premium_paywall_shown', {'source': source});

  Future<void> logPremiumPurchaseStarted(String packageId) =>
      _log('premium_purchase_started', {'package_id': packageId});

  Future<void> logPremiumPurchased(String packageId) =>
      _log('premium_purchased', {'package_id': packageId});

  Future<void> logPremiumRestored() =>
      _log('premium_restored', {});

  // ── Social / host events ───────────────────────────────────────────────────

  Future<void> logHostViewed(String hostUid) =>
      _log('host_viewed', {'host_uid': hostUid});

  Future<void> logHostRequestSent(String hostUid) =>
      _log('host_request_sent', {'host_uid': hostUid});

  Future<void> logPhotoShared(String curationId) =>
      _log('photo_shared', {'curation_id': curationId});

  // ── Auth events ────────────────────────────────────────────────────────────

  Future<void> logSignIn(String method) =>
      _log('sign_in', {'method': method});

  Future<void> logSignOut() =>
      _log('sign_out', {});

  // ── Onboarding events ─────────────────────────────────────────────────────

  Future<void> logOnboardingCompleted(String language, int interestsCount) =>
      _log('onboarding_completed', {
        'language': language,
        'interests_count': interestsCount,
      });

  Future<void> logOnboardingSkipped(int step) =>
      _log('onboarding_skipped', {'at_step': step});

  // ── Offline events ─────────────────────────────────────────────────────────

  Future<void> logOfflineCacheUsed(String screenName) =>
      _log('offline_cache_used', {'screen': screenName});

  Future<void> logPostCreated(String postId) =>
      _log('post_created', {'post_id': postId});

  Future<void> logPostLiked(String postId) =>
      _log('post_liked', {'post_id': postId});

  Future<void> logCommentAdded(String postId) =>
      _log('comment_added', {'post_id': postId});

  // ── Internal helper ────────────────────────────────────────────────────────

  Future<void> _log(String name, Map<String, Object> params) async {
    if (kDebugMode) return;
    try {
      await _fa.logEvent(name: name, parameters: params);
    } catch (_) {}
  }
}

final analyticsService = AnalyticsService._();

// ── GoRouter NavigatorObserver ──────────────────────────────────────────────

class AppAnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _track(newRoute);
  }

  void _track(Route route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty && name != '/') {
      analyticsService.logScreenView(name);
    }
  }
}
