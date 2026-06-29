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
  final String title;
  final String subtitle;
  final String description;
  final String? titleEn;
  final String? subtitleEn;
  final String? descriptionEn;
  final String imageUrl;
  final String? videoUrl;
  final List<String> tags;
  final int level;
  final DateTime createdAt;
  final int readTime;
  final String sourceUrl;
  final bool isPremium;
  final List<String> keyFacts;
  final List<String>? keyFactsEn;
  final String? didYouKnow;
  final String? didYouKnowEn;
  final List<String> seeAlso;

  CultureContent({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.description,
    this.titleEn,
    this.subtitleEn,
    this.descriptionEn,
    required this.imageUrl,
    this.videoUrl,
    required this.tags,
    required this.level,
    required this.createdAt,
    required this.readTime,
    required this.sourceUrl,
    this.isPremium = false,
    this.keyFacts = const [],
    this.keyFactsEn,
    this.didYouKnow,
    this.didYouKnowEn,
    this.seeAlso = const [],
  });

  factory CultureContent.fromMap(Map<String, dynamic> map) {
    return CultureContent(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      description: map['description'] ?? '',
      titleEn: map['titleEn'] as String?,
      subtitleEn: map['subtitleEn'] as String?,
      descriptionEn: map['descriptionEn'] as String?,
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
      keyFactsEn: map['keyFactsEn'] != null ? List<String>.from(map['keyFactsEn']) : null,
      didYouKnow: map['didYouKnow'] as String?,
      didYouKnowEn: map['didYouKnowEn'] as String?,
      seeAlso: List<String>.from(map['seeAlso'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryId': categoryId,
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'titleEn': titleEn,
    'subtitleEn': subtitleEn,
    'descriptionEn': descriptionEn,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'tags': tags,
    'level': level,
    'createdAt': createdAt.toIso8601String(),
    'readTime': readTime,
    'sourceUrl': sourceUrl,
    'isPremium': isPremium,
    'keyFacts': keyFacts,
    'keyFactsEn': keyFactsEn,
    'didYouKnow': didYouKnow,
    'didYouKnowEn': didYouKnowEn,
    'seeAlso': seeAlso,
  };

  // Localization helpers
  String getTitle(bool isEnglish) => isEnglish ? (titleEn ?? title) : title;
  String getSubtitle(bool isEnglish) => isEnglish ? (subtitleEn ?? subtitle) : subtitle;
  String getDescription(bool isEnglish) => isEnglish ? (descriptionEn ?? description) : description;
  List<String> getKeyFacts(bool isEnglish) => isEnglish ? (keyFactsEn ?? keyFacts) : keyFacts;
  String? getDidYouKnow(bool isEnglish) => isEnglish ? (didYouKnowEn ?? didYouKnow) : didYouKnow;

  String getLevelLabel() {
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Intermediate';
      case 3: return 'Advanced';
      default: return 'Unknown';
    }
  }
}
