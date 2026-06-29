import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../services/upload_service.dart';
import '../utils/constants.dart';

// ── Stream providers ────────────────────────────────────────────────

/// Posts for a specific curation spot
final curationPostsProvider =
    StreamProvider.family<List<Post>, String>((ref, curationId) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.posts)
      .where('curation_id', isEqualTo: curationId)
      .orderBy('created_at', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(Post.fromFirestore).toList());
});

/// All posts by the current user
final myPostsProvider = StreamProvider<List<Post>>((ref) {
  final user = ref.watch(appUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.posts)
      .where('author_id', isEqualTo: user.uid)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Post.fromFirestore).toList());
});

// ── Post submit notifier ─────────────────────────────────────────────

class PostNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  PostNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> submitPost({
    required String curationId,
    required String curationTitle,
    required String caption,
    File? imageFile,
  }) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(appUserProvider).valueOrNull;
      if (user == null) throw Exception('Not logged in');

      String imageUrl = '';
      if (imageFile != null) {
        imageUrl = await _ref
            .read(uploadServiceProvider)
            .uploadPostImage(user.uid, imageFile);
      }

      final post = Post(
        id: '',
        authorId: user.uid,
        authorName: user.displayName.isNotEmpty ? user.displayName : 'Explorer',
        authorAvatarUrl: user.photoUrl ?? '',
        curationId: curationId,
        curationTitle: curationTitle,
        imageUrl: imageUrl,
        caption: caption,
        likeCount: 0,
        commentCount: 0,
        createdAt: DateTime.now(),
        likedByMe: false,
      );

      await FirebaseFirestore.instance
          .collection(FirestoreCollections.posts)
          .add(post.toFirestore());

      // Award XP for posting
      final docRef = FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (snap.exists) {
          final currentXp = (snap.data()?['xp'] ?? 0) as int;
          final postCount = (snap.data()?['total_posts'] ?? 0) as int;
          tx.update(docRef, {
            'xp': currentXp + AppConstants.xpReviewPost,
            'total_posts': postCount + 1,
          });
        }
      });

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final postNotifierProvider =
    StateNotifierProvider<PostNotifier, AsyncValue<void>>(
  (ref) => PostNotifier(ref),
);
