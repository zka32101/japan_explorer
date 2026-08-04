class UserContribution {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String imageHash;
  final String analysisType;
  final String title;
  final String answerTitle;
  final String description;
  final String imageUrl;
  final int voteCount;
  final bool isBeingEditedByUser;
  final DateTime createdAt;
  final double? creatorRevenueUsd;

  UserContribution({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.imageHash,
    required this.analysisType,
    required this.title,
    this.answerTitle = '',
    required this.description,
    required this.imageUrl,
    required this.voteCount,
    required this.isBeingEditedByUser,
    required this.createdAt,
    this.creatorRevenueUsd,
  });

  factory UserContribution.fromMap(Map<String, dynamic> map) {
    return UserContribution(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatarUrl: map['userAvatarUrl'] ?? '',
      imageHash: map['imageHash'] ?? '',
      analysisType: map['analysisType'] ?? 'what_is_this',
      title: map['title'] ?? '',
      answerTitle: map['answerTitle'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      voteCount: map['voteCount'] ?? 0,
      isBeingEditedByUser: map['isBeingEditedByUser'] ?? false,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      creatorRevenueUsd: (map['creatorRevenueUsd'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'userAvatarUrl': userAvatarUrl,
    'imageHash': imageHash,
    'analysisType': analysisType,
    'title': title,
    'answerTitle': answerTitle,
    'description': description,
    'imageUrl': imageUrl,
    'voteCount': voteCount,
    'isBeingEditedByUser': isBeingEditedByUser,
    'createdAt': createdAt.toIso8601String(),
    'creatorRevenueUsd': creatorRevenueUsd,
  };
}

class ContributionVote {
  final String id;
  final String contributionId;
  final String userId;
  final int voteValue;
  final DateTime createdAt;

  ContributionVote({
    required this.id,
    required this.contributionId,
    required this.userId,
    required this.voteValue,
    required this.createdAt,
  });

  factory ContributionVote.fromMap(Map<String, dynamic> map) {
    return ContributionVote(
      id: map['id'] ?? '',
      contributionId: map['contributionId'] ?? '',
      userId: map['userId'] ?? '',
      voteValue: map['voteValue'] ?? 0,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'contributionId': contributionId,
    'userId': userId,
    'voteValue': voteValue,
    'createdAt': createdAt.toIso8601String(),
  };
}
