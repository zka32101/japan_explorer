import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum JournalMood { amazing, great, good, okay, tough }

extension JournalMoodX on JournalMood {
  String get emoji {
    switch (this) {
      case JournalMood.amazing: return '🤩';
      case JournalMood.great:   return '😄';
      case JournalMood.good:    return '😊';
      case JournalMood.okay:    return '😐';
      case JournalMood.tough:   return '😓';
    }
  }

  String get label {
    switch (this) {
      case JournalMood.amazing: return 'Amazing';
      case JournalMood.great:   return 'Great';
      case JournalMood.good:    return 'Good';
      case JournalMood.okay:    return 'Okay';
      case JournalMood.tough:   return 'Tough day';
    }
  }

  static JournalMood fromString(String s) =>
      JournalMood.values.firstWhere((e) => e.name == s,
          orElse: () => JournalMood.good);
}

class JournalEntry {
  final String id;
  final String userId;
  final String curationId;
  final String curationTitle;
  final String content;
  final String imageUrl;
  final JournalMood mood;
  final DateTime visitDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.curationId,
    required this.curationTitle,
    required this.content,
    required this.imageUrl,
    required this.mood,
    required this.visitDate,
    required this.createdAt,
    required this.updatedAt,
  });

  JournalEntry copyWith({
    String? content,
    String? imageUrl,
    JournalMood? mood,
    DateTime? visitDate,
    DateTime? updatedAt,
  }) =>
      JournalEntry(
        id: id,
        userId: userId,
        curationId: curationId,
        curationTitle: curationTitle,
        content: content ?? this.content,
        imageUrl: imageUrl ?? this.imageUrl,
        mood: mood ?? this.mood,
        visitDate: visitDate ?? this.visitDate,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  // ── Firestore ──────────────────────────────────────────────────────────────

  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return JournalEntry(
      id: doc.id,
      userId: d['user_id'] ?? '',
      curationId: d['curation_id'] ?? '',
      curationTitle: d['curation_title'] ?? '',
      content: d['content'] ?? '',
      imageUrl: d['image_url'] ?? '',
      mood: JournalMoodX.fromString(d['mood'] ?? 'good'),
      visitDate: d['visit_date'] != null
          ? (d['visit_date'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: d['created_at'] != null
          ? (d['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: d['updated_at'] != null
          ? (d['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'user_id': userId,
        'curation_id': curationId,
        'curation_title': curationTitle,
        'content': content,
        'image_url': imageUrl,
        'mood': mood.name,
        'visit_date': Timestamp.fromDate(visitDate),
        'created_at': Timestamp.fromDate(createdAt),
        'updated_at': Timestamp.fromDate(updatedAt),
      };

  // ── Hive (JSON) ────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'curation_id': curationId,
        'curation_title': curationTitle,
        'content': content,
        'image_url': imageUrl,
        'mood': mood.name,
        'visit_date_ms': visitDate.millisecondsSinceEpoch,
        'created_at_ms': createdAt.millisecondsSinceEpoch,
        'updated_at_ms': updatedAt.millisecondsSinceEpoch,
      };

  factory JournalEntry.fromMap(Map<String, dynamic> m) => JournalEntry(
        id: m['id'] as String,
        userId: m['user_id'] ?? '',
        curationId: m['curation_id'] ?? '',
        curationTitle: m['curation_title'] ?? '',
        content: m['content'] ?? '',
        imageUrl: m['image_url'] ?? '',
        mood: JournalMoodX.fromString(m['mood'] ?? 'good'),
        visitDate: DateTime.fromMillisecondsSinceEpoch(
            m['visit_date_ms'] ?? 0),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            m['created_at_ms'] ?? 0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            m['updated_at_ms'] ?? 0),
      );

  String toJson() => json.encode(toMap());
  factory JournalEntry.fromJson(String src) =>
      JournalEntry.fromMap(json.decode(src) as Map<String, dynamic>);
}
