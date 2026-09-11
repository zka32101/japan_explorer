import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Language { ja, en, zh, ko, fr }

extension LanguageCode on Language {
  String get code {
    switch (this) {
      case Language.ja: return 'ja';
      case Language.en: return 'en';
      case Language.zh: return 'zh';
      case Language.ko: return 'ko';
      case Language.fr: return 'fr';
    }
  }

  String get displayName {
    switch (this) {
      case Language.ja: return '日本語';
      case Language.en: return 'English';
      case Language.zh: return '中文';
      case Language.ko: return '한국어';
      case Language.fr: return 'Français';
    }
  }
}

class LanguageNotifier extends StateNotifier<Language> {
  LanguageNotifier() : super(Language.ja) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('language') ?? 'ja';
      state = _codeToLanguage(code);
    } catch (_) {
      state = Language.ja;
    }
  }

  Language _codeToLanguage(String code) {
    switch (code) {
      case 'en': return Language.en;
      case 'zh': return Language.zh;
      case 'ko': return Language.ko;
      case 'fr': return Language.fr;
      default: return Language.ja;
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
