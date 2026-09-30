import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Translated text of one culture article (see `scripts/build_culture_assets.py`).
///
/// Every field is optional: whatever is missing falls back to the English
/// original that ships with the article itself.
@immutable
class CultureTranslation {
  const CultureTranslation({
    this.title,
    this.subtitle,
    this.description,
    this.keyFacts,
    this.didYouKnow,
  });

  final String? title;
  final String? subtitle;
  final String? description;
  final List<String>? keyFacts;
  final String? didYouKnow;

  /// Compact form stored in the assets: t / s / d / k / y.
  factory CultureTranslation.fromCompact(Map<String, dynamic> map) {
    final facts = map['k'];
    return CultureTranslation(
      title: map['t'] as String?,
      subtitle: map['s'] as String?,
      description: map['d'] as String?,
      keyFacts: facts is List ? List<String>.from(facts) : null,
      didYouKnow: map['y'] as String?,
    );
  }
}

/// Culture-article translations bundled as `assets/culture_content/<lang>.json`.
///
/// Only the language in use is loaded (lazily, off the UI isolate); the other
/// languages never touch memory. Lookups are synchronous so the existing
/// `CultureContent.localized*` helpers keep their signature.
class CultureTranslationStore {
  CultureTranslationStore._();

  static final CultureTranslationStore instance = CultureTranslationStore._();

  final Map<String, Map<String, CultureTranslation>> _byLanguage = {};
  final Map<String, Future<void>> _loading = {};

  /// Languages with no bundled file (English is the source language).
  final Set<String> _unavailable = {'en'};

  bool isLoaded(String langCode) => _byLanguage.containsKey(langCode);

  /// The translation of [articleId] in [langCode], or null (not loaded, no
  /// file for that language, or the article is not translated).
  CultureTranslation? lookup(String articleId, String langCode) =>
      _byLanguage[langCode]?[articleId];

  /// Loads [langCode] once. Safe to call repeatedly; never throws.
  Future<void> ensureLoaded(String langCode) {
    if (_byLanguage.containsKey(langCode) || _unavailable.contains(langCode)) {
      return Future.value();
    }
    final future = _loading[langCode] ??= _load(langCode);
    return future;
  }

  Future<void> _load(String langCode) async {
    try {
      final raw = await rootBundle.loadString('assets/culture_content/$langCode.json');
      // Decoding ~4 MB of JSON would jank the UI thread.
      final parsed = await compute(_decode, raw);
      _byLanguage[langCode] = parsed;
    } catch (e) {
      // No file for this language (or it is unreadable): use English.
      _unavailable.add(langCode);
      if (kDebugMode) debugPrint('CultureTranslationStore: $langCode unavailable ($e)');
    } finally {
      // Only the map entry is dropped; the future itself already completed.
      unawaited(Future.value(_loading.remove(langCode)));
    }
  }

  @visibleForTesting
  void debugSet(String langCode, Map<String, CultureTranslation> data) {
    _byLanguage[langCode] = data;
  }

  @visibleForTesting
  void debugReset() {
    _byLanguage.clear();
    _loading.clear();
    _unavailable
      ..clear()
      ..add('en');
  }
}

Map<String, CultureTranslation> _decode(String raw) {
  final map = jsonDecode(raw) as Map<String, dynamic>;
  return {
    for (final e in map.entries)
      e.key: CultureTranslation.fromCompact(e.value as Map<String, dynamic>),
  };
}
