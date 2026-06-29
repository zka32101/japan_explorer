import 'package:cloud_firestore/cloud_firestore.dart';

// ── HostProfile ───────────────────────────────────────────────────────────────

class HostProfile {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String bio;
  final String city;
  final List<String> areas;       // neighborhoods / districts where they guide
  final List<String> interests;   // culture, food, history, modern, nature...
  final List<String> languages;   // ISO 639-1: en, ja, zh, ko, fr...
  final double rating;
  final int reviewCount;
  final int meetupsCompleted;
  final bool isActive;
  final DateTime createdAt;

  const HostProfile({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.bio,
    required this.city,
    required this.areas,
    required this.interests,
    required this.languages,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.meetupsCompleted = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory HostProfile.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return HostProfile(
      uid: doc.id,
      displayName: d['display_name'] as String? ?? '',
      photoUrl: d['photo_url'] as String?,
      bio: d['bio'] as String? ?? '',
      city: d['city'] as String? ?? '',
      areas: List<String>.from(d['areas'] as List? ?? []),
      interests: List<String>.from(d['interests'] as List? ?? []),
      languages: List<String>.from(d['languages'] as List? ?? ['en']),
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: d['review_count'] as int? ?? 0,
      meetupsCompleted: d['meetups_completed'] as int? ?? 0,
      isActive: d['is_active'] as bool? ?? true,
      createdAt: d['created_at'] != null
          ? (d['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'display_name': displayName,
        'photo_url': photoUrl,
        'bio': bio,
        'city': city,
        'areas': areas,
        'interests': interests,
        'languages': languages,
        'rating': rating,
        'review_count': reviewCount,
        'meetups_completed': meetupsCompleted,
        'is_active': isActive,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

  /// Formatted language labels for display.
  String get languageDisplay {
    const labels = {
      'en': '🇬🇧 EN',
      'ja': '🇯🇵 JA',
      'zh': '🇨🇳 ZH',
      'ko': '🇰🇷 KO',
      'fr': '🇫🇷 FR',
      'es': '🇪🇸 ES',
      'de': '🇩🇪 DE',
    };
    return languages.map((l) => labels[l] ?? l.toUpperCase()).join(' · ');
  }

  HostProfile copyWith({
    String? bio,
    String? city,
    List<String>? areas,
    List<String>? interests,
    List<String>? languages,
    bool? isActive,
  }) =>
      HostProfile(
        uid: uid,
        displayName: displayName,
        photoUrl: photoUrl,
        bio: bio ?? this.bio,
        city: city ?? this.city,
        areas: areas ?? this.areas,
        interests: interests ?? this.interests,
        languages: languages ?? this.languages,
        rating: rating,
        reviewCount: reviewCount,
        meetupsCompleted: meetupsCompleted,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}

// ── HostRequest ───────────────────────────────────────────────────────────────

enum RequestStatus { pending, accepted, declined, completed }

extension RequestStatusExt on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending: return 'Pending';
      case RequestStatus.accepted: return 'Accepted';
      case RequestStatus.declined: return 'Declined';
      case RequestStatus.completed: return 'Completed';
    }
  }

  bool get isActive =>
      this == RequestStatus.pending || this == RequestStatus.accepted;
}

class HostRequest {
  final String id;
  final String guestUid;
  final String guestName;
  final String hostUid;
  final String hostName;
  final String city;
  final String? area;
  final String message;
  final RequestStatus status;
  final DateTime createdAt;

  const HostRequest({
    required this.id,
    required this.guestUid,
    required this.guestName,
    required this.hostUid,
    required this.hostName,
    required this.city,
    this.area,
    required this.message,
    this.status = RequestStatus.pending,
    required this.createdAt,
  });

  factory HostRequest.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return HostRequest(
      id: doc.id,
      guestUid: d['guest_uid'] as String? ?? '',
      guestName: d['guest_name'] as String? ?? '',
      hostUid: d['host_uid'] as String? ?? '',
      hostName: d['host_name'] as String? ?? '',
      city: d['city'] as String? ?? '',
      area: d['area'] as String?,
      message: d['message'] as String? ?? '',
      status: RequestStatus.values.firstWhere(
        (s) => s.name == (d['status'] as String? ?? 'pending'),
        orElse: () => RequestStatus.pending,
      ),
      createdAt: d['created_at'] != null
          ? (d['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'guest_uid': guestUid,
        'guest_name': guestName,
        'host_uid': hostUid,
        'host_name': hostName,
        'city': city,
        'area': area,
        'message': message,
        'status': status.name,
        'created_at': FieldValue.serverTimestamp(),
      };
}
