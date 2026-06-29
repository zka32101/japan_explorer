import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Language { ja, en }

extension LanguageCode on Language {
  String get code {
    switch (this) {
      case Language.ja: return 'ja';
      case Language.en: return 'en';
    }
  }

  String get displayName {
    switch (this) {
      case Language.ja: return '日本語';
      case Language.en: return 'English';
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
      state = code == 'en' ? Language.en : Language.ja;
    } catch (_) {
      state = Language.ja;
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
