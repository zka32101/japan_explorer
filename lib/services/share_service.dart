import 'dart:math';
import 'package:share_plus/share_plus.dart';
import '../models/curation.dart';
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

  /// Share the app itself (e.g. from Profile screen).
  Future<void> shareApp() async {
    const text = '🗾 Discover Japan like a local with Japan Explorer!\n\n'
        'AI audio guides, trip planning, cultural challenges & more.\n\n'
        'https://japanexplorer.app';
    await Share.share(text, subject: 'Japan Explorer App');
  }

  /// Share a referral code so a friend can redeem it after signing up.
  Future<void> shareReferralCode(String code) async {
    final text = '🗾 Join me on Japan Explorer!\n\n'
        'Use my invite code $code when you sign up and we both get a bonus.\n\n'
        'https://japanexplorer.app';
    await Share.share(text, subject: 'Japan Explorer invite');
  }
}

final shareService = ShareService._();
