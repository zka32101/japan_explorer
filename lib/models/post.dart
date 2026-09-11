import 'package:cloud_firestore/cloud_firestore.dart';

/// A community post — photo + caption + optional location tag.
class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.imageUrl,
    required this.caption,
    required this.curationId,
    required this.curationTitle,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.likedByMe = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String imageUrl;
  final String caption;
  final String curationId;    // '' if not tagged to a spot
  final String curationTitle;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final bool likedByMe;       // client-side flag, not stored in Firestore

  Post copyWith({
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
  }) =>
      Post(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        imageUrl: imageUrl,
        caption: caption,
        curationId: curationId,
        curationTitle: curationTitle,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        createdAt: createdAt,
        likedByMe: likedByMe ?? this.likedByMe,
      );

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorId: m['author_id'] as String? ?? '',
      authorName: m['author_name'] as String? ?? '',
      authorAvatarUrl: m['author_avatar_url'] as String? ?? '',
      imageUrl: m['image_url'] as String? ?? '',
      caption: m['caption'] as String? ?? '',
      curationId: m['curation_id'] as String? ?? '',
      curationTitle: m['curation_title'] as String? ?? '',
      likeCount: (m['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (m['comment_count'] as num?)?.toInt() ?? 0,
      createdAt: (m['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'author_id': authorId,
    'author_name': authorName,
    'author_avatar_url': authorAvatarUrl,
    'image_url': imageUrl,
    'caption': caption,
    'curation_id': curationId,
    'curation_title': curationTitle,
    'like_count': likeCount,
    'comment_count': commentCount,
    'created_at': FieldValue.serverTimestamp(),
  };
}

/// A comment on a post.
class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String text;
  final DateTime createdAt;

  factory PostComment.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return PostComment(
      id: doc.id,
      postId: m['post_id'] as String? ?? '',
      authorId: m['author_id'] as String? ?? '',
      authorName: m['author_name'] as String? ?? '',
      authorAvatarUrl: m['author_avatar_url'] as String? ?? '',
      text: m['text'] as String? ?? '',
      createdAt: (m['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'post_id': postId,
    'author_id': authorId,
    'author_name': authorName,
    'author_avatar_url': authorAvatarUrl,
    'text': text,
    'created_at': FieldValue.serverTimestamp(),
  };
}
