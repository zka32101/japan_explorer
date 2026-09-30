import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/culture_translation_store.dart';

/// Languages the app UI supports. Add a language here, add its
/// `assets/translations/<file>.json`, and register [Language.locale] in
/// `main.dart` (`supportedLocales`).
enum Language {
  ja('ja', '日本語', '🇯🇵', Locale('ja'), 'ja-JP', 'Japanese'),
  en('en', 'English', '🇬🇧', Locale('en'), 'en-US', 'English'),
  zh('zh', '中文', '🇨🇳', Locale('zh'), 'zh-CN', 'Simplified Chinese'),
  zhHant('zh-TW', '繁體中文', '🇹🇼', Locale('zh', 'TW'), 'zh-TW', 'Traditional Chinese'),
  ko('ko', '한국어', '🇰🇷', Locale('ko'), 'ko-KR', 'Korean'),
  fr('fr', 'Français', '🇫🇷', Locale('fr'), 'fr-FR', 'French'),
  th('th', 'ไทย', '🇹🇭', Locale('th'), 'th-TH', 'Thai'),
  es('es', 'Español', '🇪🇸', Locale('es'), 'es-ES', 'Spanish'),
  id('id', 'Bahasa Indonesia', '🇮🇩', Locale('id'), 'id-ID', 'Indonesian'),
  vi('vi', 'Tiếng Việt', '🇻🇳', Locale('vi'), 'vi-VN', 'Vietnamese'),
  pt('pt', 'Português', '🇧🇷', Locale('pt'), 'pt-BR', 'Portuguese'),
  hi('hi', 'हिन्दी', '🇮🇳', Locale('hi'), 'hi-IN', 'Hindi'),
  ar('ar', 'العربية', '🇸🇦', Locale('ar'), 'ar-SA', 'Arabic');

  const Language(
    this.code,
    this.displayName,
    this.flag,
    this.locale,
    this.ttsLocale,
    this.aiName,
  );

  /// Stored in preferences and used as the key in per-language maps.
  final String code;

  /// Name written in the language itself (shown in language pickers).
  final String displayName;
  final String flag;

  /// Locale handed to easy_localization / MaterialApp.
  final Locale locale;

  /// BCP-47 tag for text-to-speech.
  final String ttsLocale;

  /// Language name used when instructing an AI model ("Write in Thai.").
  final String aiName;

  static Language? tryFromCode(String? code) {
    for (final l in values) {
      if (l.code == code) return l;
    }
    return null;
  }

  /// The supported language matching the device locale, or English.
  static Language fromDevice() {
    final device = PlatformDispatcher.instance.locale;
    if (device.languageCode == 'zh') {
      // Traditional Chinese: Taiwan, Hong Kong, Macau or an explicit Hant script.
      final traditional = device.scriptCode == 'Hant' ||
          const {'TW', 'HK', 'MO'}.contains(device.countryCode);
      return traditional ? Language.zhHant : Language.zh;
    }
    return tryFromCode(device.languageCode) ?? Language.en;
  }
}

class LanguageNotifier extends StateNotifier<Language> {
  LanguageNotifier() : super(Language.fromDevice()) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('language');
      // Guard: only update if notifier is still active
      try {
        state = Language.tryFromCode(code) ?? Language.fromDevice();
      } catch (_) {
        // StateNotifier has been disposed
      }
    } catch (_) {
      // Silently ignore if prefs unavailable - use default
      try {
        state = Language.fromDevice();
      } catch (_) {
        // StateNotifier has been disposed
      }
    }
  }

  Future<void> setLanguage(Language language) async {
    state = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language.code);
    } catch (_) {}
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, Language>(
  (ref) => LanguageNotifier(),
);

// Extension helper to get localized text from CultureContent
extension Localized on String? {
  String orEmpty() => this ?? '';
}

/// Loads the bundled culture-article translations of the current language and
/// yields its code once they are ready. Screens that show culture articles
/// watch this so they rebuild after the (lazy) load finishes.
final cultureTranslationsProvider = FutureProvider<String>((ref) async {
  final code = ref.watch(languageProvider).code;
  await CultureTranslationStore.instance.ensureLoaded(code);
  return code;
});
