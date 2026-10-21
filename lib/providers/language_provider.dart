import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showglobe_core/showglobe_core.dart' show languageProvider;

import '../services/culture_translation_store.dart';

// Language enum and the persisted language provider live in showglobe_core.
export 'package:showglobe_core/showglobe_core.dart'
    show Language, LanguageNotifier, languageProvider;

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
