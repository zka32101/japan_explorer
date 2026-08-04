class CultureCategory {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<String> tags;

  CultureCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.tags,
  });

  factory CultureCategory.fromMap(Map<String, dynamic> map) {
    return CultureCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '',
      description: map['description'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'description': description,
    'tags': tags,
  };

  static const List<String> categoryIds = [
    'culture',
    'food',
    'region',
    'art',
    'language',
  ];

  static String getCategoryEmoji(String categoryId) {
    switch (categoryId) {
      case 'culture': return '🏮';
      case 'food': return '🍱';
      case 'region': return '🗾';
      case 'art': return '🎨';
      case 'language': return '📖';
      default: return '✨';
    }
  }

  static String label(String categoryId) {
    switch (categoryId) {
      case 'culture': return 'Culture';
      case 'food': return 'Food';
      case 'region': return 'Region';
      case 'art': return 'Art';
      case 'language': return 'Language';
      default: return 'Other';
    }
  }
}

class CultureContent {
  final String id;
  final String categoryId;
  /// Canonical (English) content — always present, used as fallback.
  final String title;
  final String subtitle;
  final String description;
  // Per-language overrides — null until translated by the content pipeline.
  final String? titleJa;
  final String? titleZh;
  final String? titleKo;
  final String? titleFr;
  final String? subtitleJa;
  final String? subtitleZh;
  final String? subtitleKo;
  final String? subtitleFr;
  final String? descriptionJa;
  final String? descriptionZh;
  final String? descriptionKo;
  final String? descriptionFr;
  final String imageUrl;
  final String? videoUrl;
  final List<String> tags;
  final int level;
  final DateTime createdAt;
  final int readTime;
  final String sourceUrl;
  final bool isPremium;
  final List<String> keyFacts;
  final List<String>? keyFactsJa;
  final List<String>? keyFactsZh;
  final List<String>? keyFactsKo;
  final List<String>? keyFactsFr;
  final String? didYouKnow;
  final String? didYouKnowJa;
  final String? didYouKnowZh;
  final String? didYouKnowKo;
  final String? didYouKnowFr;
  final List<String> seeAlso;

  CultureContent({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.description,
    this.titleJa,
    this.titleZh,
    this.titleKo,
    this.titleFr,
    this.subtitleJa,
    this.subtitleZh,
    this.subtitleKo,
    this.subtitleFr,
    this.descriptionJa,
    this.descriptionZh,
    this.descriptionKo,
    this.descriptionFr,
    required this.imageUrl,
    this.videoUrl,
    required this.tags,
    required this.level,
    required this.createdAt,
    required this.readTime,
    required this.sourceUrl,
    this.isPremium = false,
    this.keyFacts = const [],
    this.keyFactsJa,
    this.keyFactsZh,
    this.keyFactsKo,
    this.keyFactsFr,
    this.didYouKnow,
    this.didYouKnowJa,
    this.didYouKnowZh,
    this.didYouKnowKo,
    this.didYouKnowFr,
    this.seeAlso = const [],
  });

  factory CultureContent.fromMap(Map<String, dynamic> map) {
    List<String>? strList(dynamic v) => v == null ? null : List<String>.from(v);
    return CultureContent(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      description: map['description'] ?? '',
      titleJa: map['titleJa'] as String?,
      titleZh: map['titleZh'] as String?,
      titleKo: map['titleKo'] as String?,
      titleFr: map['titleFr'] as String?,
      subtitleJa: map['subtitleJa'] as String?,
      subtitleZh: map['subtitleZh'] as String?,
      subtitleKo: map['subtitleKo'] as String?,
      subtitleFr: map['subtitleFr'] as String?,
      descriptionJa: map['descriptionJa'] as String?,
      descriptionZh: map['descriptionZh'] as String?,
      descriptionKo: map['descriptionKo'] as String?,
      descriptionFr: map['descriptionFr'] as String?,
      imageUrl: map['imageUrl'] ?? '',
      videoUrl: map['videoUrl'],
      tags: List<String>.from(map['tags'] ?? []),
      level: map['level'] ?? 1,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      readTime: map['readTime'] ?? 5,
      sourceUrl: map['sourceUrl'] ?? '',
      isPremium: map['isPremium'] as bool? ?? false,
      keyFacts: List<String>.from(map['keyFacts'] ?? []),
      keyFactsJa: strList(map['keyFactsJa']),
      keyFactsZh: strList(map['keyFactsZh']),
      keyFactsKo: strList(map['keyFactsKo']),
      keyFactsFr: strList(map['keyFactsFr']),
      didYouKnow: map['didYouKnow'] as String?,
      didYouKnowJa: map['didYouKnowJa'] as String?,
      didYouKnowZh: map['didYouKnowZh'] as String?,
      didYouKnowKo: map['didYouKnowKo'] as String?,
      didYouKnowFr: map['didYouKnowFr'] as String?,
      seeAlso: List<String>.from(map['seeAlso'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryId': categoryId,
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'titleJa': titleJa,
    'titleZh': titleZh,
    'titleKo': titleKo,
    'titleFr': titleFr,
    'subtitleJa': subtitleJa,
    'subtitleZh': subtitleZh,
    'subtitleKo': subtitleKo,
    'subtitleFr': subtitleFr,
    'descriptionJa': descriptionJa,
    'descriptionZh': descriptionZh,
    'descriptionKo': descriptionKo,
    'descriptionFr': descriptionFr,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'tags': tags,
    'level': level,
    'createdAt': createdAt.toIso8601String(),
    'readTime': readTime,
    'sourceUrl': sourceUrl,
    'isPremium': isPremium,
    'keyFacts': keyFacts,
    'keyFactsJa': keyFactsJa,
    'keyFactsZh': keyFactsZh,
    'keyFactsKo': keyFactsKo,
    'keyFactsFr': keyFactsFr,
    'didYouKnow': didYouKnow,
    'didYouKnowJa': didYouKnowJa,
    'didYouKnowZh': didYouKnowZh,
    'didYouKnowKo': didYouKnowKo,
    'didYouKnowFr': didYouKnowFr,
    'seeAlso': seeAlso,
  };

  // ── Localization helpers — fall back to English (canonical) fields ────────
  String localizedTitle(String langCode) => switch (langCode) {
        'ja' => titleJa ?? title,
        'zh' => titleZh ?? title,
        'ko' => titleKo ?? title,
        'fr' => titleFr ?? title,
        _ => title,
      };

  String localizedSubtitle(String langCode) => switch (langCode) {
        'ja' => subtitleJa ?? subtitle,
        'zh' => subtitleZh ?? subtitle,
        'ko' => subtitleKo ?? subtitle,
        'fr' => subtitleFr ?? subtitle,
        _ => subtitle,
      };

  String localizedDescription(String langCode) => switch (langCode) {
        'ja' => descriptionJa ?? description,
        'zh' => descriptionZh ?? description,
        'ko' => descriptionKo ?? description,
        'fr' => descriptionFr ?? description,
        _ => description,
      };

  List<String> localizedKeyFacts(String langCode) => switch (langCode) {
        'ja' => keyFactsJa ?? keyFacts,
        'zh' => keyFactsZh ?? keyFacts,
        'ko' => keyFactsKo ?? keyFacts,
        'fr' => keyFactsFr ?? keyFacts,
        _ => keyFacts,
      };

  String? localizedDidYouKnow(String langCode) => switch (langCode) {
        'ja' => didYouKnowJa ?? didYouKnow,
        'zh' => didYouKnowZh ?? didYouKnow,
        'ko' => didYouKnowKo ?? didYouKnow,
        'fr' => didYouKnowFr ?? didYouKnow,
        _ => didYouKnow,
      };

  String getLevelLabel() {
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Intermediate';
      case 3: return 'Advanced';
      default: return 'Unknown';
    }
  }
}
