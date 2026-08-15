import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../services/analytics_service.dart';
import '../services/review_service.dart';
import '../utils/firestore_instance.dart';

// ── Feed state ────────────────────────────────────────────────────────────────

class PostFeedState {
  const PostFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  PostFeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) =>
      PostFeedState(
        posts: posts ?? this.posts,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

// ── Feed provider ─────────────────────────────────────────────────────────────

class PostFeedNotifier extends StateNotifier<PostFeedState> {
  PostFeedNotifier() : super(const PostFeedState()) {
    loadInitial();
  }

  static const _pageSize = 12;
  final _col = db.collection('posts');
  DocumentSnapshot? _lastDoc;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    _lastDoc = null;
    try {
      final snap = await _col
          .orderBy('created_at', descending: true)
          .limit(_pageSize)
          .get();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final posts = await _postsWithLikeFlag(snap.docs, uid);
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: snap.docs.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || _lastDoc == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final snap = await _col
          .orderBy('created_at', descending: true)
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize)
          .get();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final more = await _postsWithLikeFlag(snap.docs, uid);
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
      state = state.copyWith(
        posts: [...state.posts, ...more],
        isLoading: false,
        hasMore: snap.docs.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Toggle like — optimistic update + Firestore transaction
  Future<void> toggleLike(String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final idx = state.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = state.posts[idx];
    final nowLiked = !post.likedByMe;

    // Optimistic
    final updated = List<Post>.from(state.posts);
    updated[idx] = post.copyWith(
      likedByMe: nowLiked,
      likeCount: post.likeCount + (nowLiked ? 1 : -1),
    );
    state = state.copyWith(posts: updated);

    try {
      final likeRef = db
          .collection('post_likes')
          .doc('${uid}_$postId');
      final postRef = _col.doc(postId);

      await db.runTransaction((tx) async {
        if (nowLiked) {
          tx.set(likeRef, {'uid': uid, 'post_id': postId});
          tx.update(postRef, {'like_count': FieldValue.increment(1)});
        } else {
          tx.delete(likeRef);
          tx.update(postRef, {'like_count': FieldValue.increment(-1)});
        }
      });
    } catch (_) {
      // Rollback on error
      final rollback = List<Post>.from(state.posts);
      rollback[idx] = post;
      state = state.copyWith(posts: rollback);
    }
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  Future<List<Post>> _postsWithLikeFlag(
    List<DocumentSnapshot> docs,
    String? uid,
  ) async {
    final posts = docs.map(Post.fromFirestore).toList();
    if (uid == null || docs.isEmpty) return posts;

    // Batch-check which posts the current user has liked
    final likeIds = posts.map((p) => '${uid}_${p.id}').toList();
    final futures = likeIds
        .map((id) => db
            .collection('post_likes')
            .doc(id)
            .get())
        .toList();
    final results = await Future.wait(futures);
    return [
      for (var i = 0; i < posts.length; i++)
        posts[i].copyWith(likedByMe: results[i].exists),
    ];
  }
}

final postFeedProvider =
    StateNotifierProvider<PostFeedNotifier, PostFeedState>(
        (_) => PostFeedNotifier());

// ── Comments stream ───────────────────────────────────────────────────────────

final postCommentsProvider =
    StreamProvider.family<List<PostComment>, String>((ref, postId) {
  return db
      .collection('posts')
      .doc(postId)
      .collection('comments')
      .orderBy('created_at')
      .snapshots()
      .map((snap) => snap.docs.map(PostComment.fromFirestore).toList());
});

// ── Create post service ───────────────────────────────────────────────────────

class PostService {
  PostService._();

  final _firestore = db;
  final _storage = FirebaseStorage.instance;

  /// Upload image to Storage → create post document → return new [Post].
  Future<Post> createPost({
    required File imageFile,
    required String caption,
    String curationId = '',
    String curationTitle = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');

    // 1. Upload image
    final ext = imageFile.path.split('.').last;
    final storagePath =
        'posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final uploadTask = await _storage.ref(storagePath).putFile(imageFile);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    // 2. Build post
    final now = DateTime.now();
    final docRef = _firestore.collection('posts').doc();
    final post = Post(
      id: docRef.id,
      authorId: user.uid,
      authorName: user.displayName ?? 'Explorer',
      authorAvatarUrl: user.photoURL ?? '',
      imageUrl: imageUrl,
      caption: caption,
      curationId: curationId,
      curationTitle: curationTitle,
      likeCount: 0,
      commentCount: 0,
      createdAt: now,
      likedByMe: false,
    );

    await docRef.set(post.toFirestore());
    analyticsService.logPostCreated(docRef.id);
    reviewService.addEngagement(ReviewService.ptPostCreated);
    return post;
  }

  /// Add a comment to a post.
  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || text.trim().isEmpty) return;

    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc();

    final comment = PostComment(
      id: commentRef.id,
      postId: postId,
      authorId: user.uid,
      authorName: user.displayName ?? 'Explorer',
      authorAvatarUrl: user.photoURL ?? '',
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    await db.runTransaction((tx) async {
      tx.set(commentRef, comment.toFirestore());
      tx.update(
        _firestore.collection('posts').doc(postId),
        {'comment_count': FieldValue.increment(1)},
      );
    });
  }

  /// Delete own post — removes Storage image + Firestore document.
  Future<void> deletePost(Post post) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid != post.authorId) return;
    try {
      await _storage.refFromURL(post.imageUrl).delete();
    } catch (_) {} // ignore if already deleted
    await _firestore.collection('posts').doc(post.id).delete();
  }
}

final postService = PostService._();
