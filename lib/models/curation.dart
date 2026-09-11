import 'package:cloud_firestore/cloud_firestore.dart';

class Curation {
  final String id;
  final String title;
  final String titleJa;
  final String description;
  final String descriptionJa;
  final String category;
  final String prefecture;
  final String city;
  final List<String> imageUrls;
  final GeoPoint location;
  final double averageWantToGo;
  final double averageRecommend;
  final int totalRatings;
  final int overallRank;
  final int categoryRank;
  final Map<String, dynamic> practicalInfo;
  final List<String> tags;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Curation({
    required this.id,
    required this.title,
    required this.titleJa,
    required this.description,
    required this.descriptionJa,
    required this.category,
    required this.prefecture,
    required this.city,
    required this.imageUrls,
    required this.location,
    required this.averageWantToGo,
    required this.averageRecommend,
    required this.totalRatings,
    required this.overallRank,
    required this.categoryRank,
    required this.practicalInfo,
    required this.tags,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Curation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Curation(
      id: doc.id,
      title: data['title'] ?? '',
      titleJa: data['title_ja'] ?? '',
      description: data['description'] ?? '',
      descriptionJa: data['description_ja'] ?? '',
      category: data['category'] ?? '',
      prefecture: data['prefecture'] ?? '',
      city: data['city'] ?? '',
      imageUrls: List<String>.from(data['image_urls'] ?? []),
      location: data['location'] as GeoPoint,
      averageWantToGo: (data['avg_want_to_go'] ?? 0.0).toDouble(),
      averageRecommend: (data['avg_recommend'] ?? 0.0).toDouble(),
      totalRatings: data['total_ratings'] ?? 0,
      overallRank: data['overall_rank'] ?? 0,
      categoryRank: data['category_rank'] ?? 0,
      practicalInfo: Map<String, dynamic>.from(data['practical_info'] ?? {}),
      tags: List<String>.from(data['tags'] ?? []),
      isActive: data['is_active'] ?? true,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'title_ja': titleJa,
        'description': description,
        'description_ja': descriptionJa,
        'category': category,
        'prefecture': prefecture,
        'city': city,
        'image_urls': imageUrls,
        'location': location,
        'avg_want_to_go': averageWantToGo,
        'avg_recommend': averageRecommend,
        'total_ratings': totalRatings,
        'overall_rank': overallRank,
        'category_rank': categoryRank,
        'practical_info': practicalInfo,
        'tags': tags,
        'is_active': isActive,
        'created_at': Timestamp.fromDate(createdAt),
        'updated_at': Timestamp.fromDate(updatedAt),
      };

  Curation copyWith({
    double? averageWantToGo,
    double? averageRecommend,
    int? totalRatings,
    int? overallRank,
    int? categoryRank,
  }) =>
      Curation(
        id: id,
        title: title,
        titleJa: titleJa,
        description: description,
        descriptionJa: descriptionJa,
        category: category,
        prefecture: prefecture,
        city: city,
        imageUrls: imageUrls,
        location: location,
        averageWantToGo: averageWantToGo ?? this.averageWantToGo,
        averageRecommend: averageRecommend ?? this.averageRecommend,
        totalRatings: totalRatings ?? this.totalRatings,
        overallRank: overallRank ?? this.overallRank,
        categoryRank: categoryRank ?? this.categoryRank,
        practicalInfo: practicalInfo,
        tags: tags,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  // ── JSON-serializable map (for Hive offline cache) ─────────────────────────
  // GeoPoint and Timestamp are Firestore-only types; we flatten them here.

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'title_ja': titleJa,
        'description': description,
        'description_ja': descriptionJa,
        'category': category,
        'prefecture': prefecture,
        'city': city,
        'image_urls': imageUrls,
        'location_lat': location.latitude,
        'location_lng': location.longitude,
        'avg_want_to_go': averageWantToGo,
        'avg_recommend': averageRecommend,
        'total_ratings': totalRatings,
        'overall_rank': overallRank,
        'category_rank': categoryRank,
        'practical_info': practicalInfo,
        'tags': tags,
        'is_active': isActive,
        'created_at_ms': createdAt.millisecondsSinceEpoch,
        'updated_at_ms': updatedAt.millisecondsSinceEpoch,
      };

  factory Curation.fromMap(Map<String, dynamic> m) => Curation(
        id: m['id'] as String,
        title: m['title'] ?? '',
        titleJa: m['title_ja'] ?? '',
        description: m['description'] ?? '',
        descriptionJa: m['description_ja'] ?? '',
        category: m['category'] ?? '',
        prefecture: m['prefecture'] ?? '',
        city: m['city'] ?? '',
        imageUrls: List<String>.from(m['image_urls'] ?? []),
        location: GeoPoint(
          (m['location_lat'] as num).toDouble(),
          (m['location_lng'] as num).toDouble(),
        ),
        averageWantToGo: (m['avg_want_to_go'] ?? 0.0).toDouble(),
        averageRecommend: (m['avg_recommend'] ?? 0.0).toDouble(),
        totalRatings: m['total_ratings'] ?? 0,
        overallRank: m['overall_rank'] ?? 0,
        categoryRank: m['category_rank'] ?? 0,
        practicalInfo: Map<String, dynamic>.from(m['practical_info'] ?? {}),
        tags: List<String>.from(m['tags'] ?? []),
        isActive: m['is_active'] ?? true,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            m['created_at_ms'] ?? 0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            m['updated_at_ms'] ?? 0),
      );
}

class CurationCategory {
  static const shrine = 'shrine';
  static const temple = 'temple';
  static const nature = 'nature';
  static const food = 'food';
  static const culture = 'culture';
  static const modern = 'modern';
  static const nightlife = 'nightlife';
  static const shopping = 'shopping';

  static const all = [
    shrine,
    temple,
    nature,
    food,
    culture,
    modern,
    nightlife,
    shopping,
  ];

  static String label(String category) {
    switch (category) {
      case shrine:
        return '神社';
      case temple:
        return 'お寺';
      case nature:
        return '自然';
      case food:
        return 'グルメ';
      case culture:
        return '文化';
      case modern:
        return '現代';
      case nightlife:
        return 'ナイトライフ';
      case shopping:
        return 'ショッピング';
      default:
        return category;
    }
  }

  static String emoji(String category) {
    switch (category) {
      case shrine:
        return '⛩️';
      case temple:
        return '🛕';
      case nature:
        return '🌿';
      case food:
        return '🍜';
      case culture:
        return '🎭';
      case modern:
        return '🏙️';
      case nightlife:
        return '🌃';
      case shopping:
        return '🛍️';
      default:
        return '📍';
    }
  }
}
