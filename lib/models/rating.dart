import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String curationId;
  final String userId;
  final double wantToGo;
  final double recommend;
  final bool isOutlier;
  final DateTime createdAt;

  const Rating({
    required this.id,
    required this.curationId,
    required this.userId,
    required this.wantToGo,
    required this.recommend,
    required this.isOutlier,
    required this.createdAt,
  });

  factory Rating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Rating(
      id: doc.id,
      curationId: data['curation_id'] ?? '',
      userId: data['user_id'] ?? '',
      wantToGo: (data['want_to_go'] ?? 0.0).toDouble(),
      recommend: (data['recommend'] ?? 0.0).toDouble(),
      isOutlier: data['is_outlier'] ?? false,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'curation_id': curationId,
        'user_id': userId,
        'want_to_go': wantToGo,
        'recommend': recommend,
        'is_outlier': isOutlier,
        'created_at': Timestamp.fromDate(createdAt),
      };
}

class Plan {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final List<PlanSpot> spots;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Plan({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.spots,
    this.startDate,
    this.endDate,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Plan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Plan(
      id: doc.id,
      userId: data['user_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      spots: (data['spots'] as List? ?? [])
          .map((s) => PlanSpot.fromMap(s as Map<String, dynamic>))
          .toList(),
      startDate: data['start_date'] != null
          ? (data['start_date'] as Timestamp).toDate()
          : null,
      endDate: data['end_date'] != null
          ? (data['end_date'] as Timestamp).toDate()
          : null,
      isPublic: data['is_public'] ?? false,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'user_id': userId,
        'title': title,
        'description': description,
        'spots': spots.map((s) => s.toMap()).toList(),
        'start_date': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'end_date': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'is_public': isPublic,
        'created_at': Timestamp.fromDate(createdAt),
        'updated_at': Timestamp.fromDate(updatedAt),
      };
}

class PlanSpot {
  final String curationId;
  final String curationTitle;
  final String? imageUrl;
  final int order;
  final int? dayNumber;
  final String? note;
  final DateTime? visitTime;

  const PlanSpot({
    required this.curationId,
    required this.curationTitle,
    this.imageUrl,
    required this.order,
    this.dayNumber,
    this.note,
    this.visitTime,
  });

  factory PlanSpot.fromMap(Map<String, dynamic> map) => PlanSpot(
        curationId: map['curation_id'] ?? '',
        curationTitle: map['curation_title'] ?? '',
        imageUrl: map['image_url'],
        order: map['order'] ?? 0,
        dayNumber: map['day_number'],
        note: map['note'],
        visitTime: map['visit_time'] != null
            ? (map['visit_time'] as Timestamp).toDate()
            : null,
      );

  Map<String, dynamic> toMap() => {
        'curation_id': curationId,
        'curation_title': curationTitle,
        'image_url': imageUrl,
        'order': order,
        'day_number': dayNumber,
        'note': note,
        'visit_time': visitTime != null ? Timestamp.fromDate(visitTime!) : null,
      };

  PlanSpot copyWith({
    int? order,
    int? dayNumber,
    String? note,
    DateTime? visitTime,
  }) =>
      PlanSpot(
        curationId: curationId,
        curationTitle: curationTitle,
        imageUrl: imageUrl,
        order: order ?? this.order,
        dayNumber: dayNumber ?? this.dayNumber,
        note: note ?? this.note,
        visitTime: visitTime ?? this.visitTime,
      );
}
