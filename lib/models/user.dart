import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<String> preferredCategories;
  final int xp;
  final int level;
  final List<String> badges;
  final int streakDays;
  final DateTime? lastActiveDate;
  final int streakRecoveryUsed;
  final List<String> savedCurationIds;
  final List<String> readCultureIds;
  final String languageCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.preferredCategories,
    required this.xp,
    required this.level,
    required this.badges,
    required this.streakDays,
    this.lastActiveDate,
    required this.streakRecoveryUsed,
    required this.savedCurationIds,
    this.readCultureIds = const [],
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['display_name'] ?? '',
      photoUrl: data['photo_url'],
      preferredCategories: List<String>.from(data['preferred_categories'] ?? []),
      xp: data['xp'] ?? 0,
      level: data['level'] ?? 1,
      badges: List<String>.from(data['badges'] ?? []),
      streakDays: data['streak_days'] ?? 0,
      lastActiveDate: data['last_active_date'] != null
          ? (data['last_active_date'] as Timestamp).toDate()
          : null,
      streakRecoveryUsed: data['streak_recovery_used'] ?? 0,
      savedCurationIds: List<String>.from(data['saved_curation_ids'] ?? []),
      readCultureIds: List<String>.from(data['read_culture_ids'] ?? []),
      languageCode: data['language_code'] ?? 'en',
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'display_name': displayName,
        'photo_url': photoUrl,
        'preferred_categories': preferredCategories,
        'xp': xp,
        'level': level,
        'badges': badges,
        'streak_days': streakDays,
        'last_active_date':
            lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
        'streak_recovery_used': streakRecoveryUsed,
        'saved_curation_ids': savedCurationIds,
        'read_culture_ids': readCultureIds,
        'language_code': languageCode,
        'created_at': Timestamp.fromDate(createdAt),
        'updated_at': Timestamp.fromDate(updatedAt),
      };

  int get levelXpRequired {
    switch (level) {
      case 1:
        return 500;
      case 2:
        return 1000;
      case 3:
        return 1500;
      case 4:
        return 2500;
      case 5:
        return 3000;
      case 6:
        return 4000;
      case 7:
        return 5000;
      case 8:
        return 6000;
      case 9:
        return 8000;
      default:
        return 999999;
    }
  }

  String get levelTitle {
    switch (level) {
      case 1:
        return 'Tourist';
      case 2:
        return 'Tourist+';
      case 3:
        return 'Traveler';
      case 4:
        return 'Traveler+';
      case 5:
        return 'Explorer';
      case 6:
        return 'Explorer+';
      case 7:
        return 'Cultural Ambassador';
      case 8:
        return 'Cultural Ambassador+';
      case 9:
        return 'Japan Expert';
      case 10:
        return 'Japan Master';
      default:
        return 'Japan Master';
    }
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    List<String>? preferredCategories,
    int? xp,
    int? level,
    List<String>? badges,
    int? streakDays,
    DateTime? lastActiveDate,
    int? streakRecoveryUsed,
    List<String>? savedCurationIds,
    List<String>? readCultureIds,
    String? languageCode,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        preferredCategories: preferredCategories ?? this.preferredCategories,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        badges: badges ?? this.badges,
        streakDays: streakDays ?? this.streakDays,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
        streakRecoveryUsed: streakRecoveryUsed ?? this.streakRecoveryUsed,
        savedCurationIds: savedCurationIds ?? this.savedCurationIds,
        readCultureIds: readCultureIds ?? this.readCultureIds,
        languageCode: languageCode ?? this.languageCode,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
