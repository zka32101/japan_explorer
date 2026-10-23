import 'package:share_plus/share_plus.dart';

import '../config/app_brand.dart';
import '../models/curation.dart';
import '../models/rating.dart' show Plan, PlanSpot;
import 'analytics_service.dart';

/// Builds share payloads and invokes the OS share sheet.
class ShareService {
  ShareService._();

  static const _kBaseUrl = 'https://japanexplorer.app/spots';

  /// Share a curation spot with title, excerpt, and deep-link URL.
  Future<void> shareCuration(Curation curation) async {
    final excerpt = curation.description.length > 100
        ? '${curation.description.substring(0, 100)}…'
        : curation.description;

    final text = '${curation.title}\n\n'
        '${CurationCategory.emoji(curation.category)} ${curation.city}, ${curation.prefecture}\n\n'
        '$excerpt\n\n'
        '$_kBaseUrl/${curation.id}';

    await Share.share(text, subject: curation.title);
    analyticsService.logPhotoShared(curation.id);
  }

  /// Plain-text version of a plan: title, optional description and dates, the
  /// spots in the given order (grouped by day when days are set), app link.
  static String planShareText(Plan plan, List<PlanSpot> spots) {
    String date(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final b = StringBuffer('🗾 ${plan.title}\n');
    final desc = plan.description?.trim() ?? '';
    if (desc.isNotEmpty) b.write('$desc\n');
    if (plan.startDate != null) {
      final end = plan.endDate;
      b.write(end == null || end == plan.startDate
          ? '📅 ${date(plan.startDate!)}\n'
          : '📅 ${date(plan.startDate!)} – ${date(end)}\n');
    }

    int? currentDay;
    var n = 0;
    var first = true;
    for (final s in spots) {
      if (first || s.dayNumber != currentDay) {
        b.write('\n');
        if (s.dayNumber != null) b.write('Day ${s.dayNumber}\n');
        currentDay = s.dayNumber;
        n = 0;
        first = false;
      }
      n++;
      final note = s.note?.trim() ?? '';
      b.write('$n. ${s.curationTitle}${note.isEmpty ? '' : ' — $note'}\n');
    }

    b.write('\nMade with ${tripBrand.displayName}\n$playStoreUrl');
    return b.toString();
  }

  /// Share a trip plan via the OS share sheet.
  Future<void> sharePlan(Plan plan, List<PlanSpot> spots) async {
    await Share.share(planShareText(plan, spots), subject: plan.title);
  }

  /// Share the app itself (e.g. from Profile screen).
  Future<void> shareApp() async {
    final text = '🗾 Discover Japan like a local with ${tripBrand.displayName}!\n\n'
        'AI audio guides, trip planning, cultural challenges & more.\n\n'
        '$playStoreUrl';
    await Share.share(text, subject: '${tripBrand.displayName} App');
  }

  /// Share a referral code so a friend can redeem it after signing up.
  Future<void> shareReferralCode(String code) async {
    final text = '🗾 Join me on ${tripBrand.displayName}!\n\n'
        'Use my invite code $code when you sign up and we both get a bonus.\n\n'
        '$playStoreUrl';
    await Share.share(text, subject: '${tripBrand.displayName} invite');
  }
}

final shareService = ShareService._();
