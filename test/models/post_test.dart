import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:japan_explorer/models/post.dart';

void main() {
  group('Post model', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('toFirestore / fromFirestore round-trip', () async {
      // DateTime cannot be const — use a plain instance
      final post = Post(
        id: '',
        authorId: 'user1',
        authorName: 'Taro',
        authorAvatarUrl: 'https://example.com/avatar.png',
        imageUrl: 'https://example.com/photo.png',
        caption: 'Amazing shrine!',
        curationId: 'spot42',
        curationTitle: 'Fushimi Inari',
        likeCount: 4,
        commentCount: 2,
        createdAt: DateTime(2024, 1, 1),
      );

      final ref = await fakeFirestore
          .collection('posts')
          .add(post.toFirestore());
      final doc = await ref.get();
      final restored = Post.fromFirestore(doc);

      expect(restored.authorId, 'user1');
      expect(restored.authorName, 'Taro');
      expect(restored.curationId, 'spot42');
      expect(restored.curationTitle, 'Fushimi Inari');
      expect(restored.caption, 'Amazing shrine!');
      expect(restored.likeCount, 4);
      expect(restored.commentCount, 2);
    });

    test('fromFirestore uses defaults for missing fields', () async {
      final ref = await fakeFirestore.collection('posts').add({
        'author_id': 'u1',
        'author_name': 'Jane',
        'curation_id': 'c1',
        'curation_title': 'Spot',
        'caption': 'Nice',
        // author_avatar_url, image_url, like_count, comment_count omitted
      });
      final doc = await ref.get();
      final post = Post.fromFirestore(doc);

      expect(post.likeCount, 0);
      expect(post.commentCount, 0);
      expect(post.imageUrl, '');
      expect(post.authorAvatarUrl, '');
    });

    test('copyWith updates only the given fields', () {
      final post = Post(
        id: 'p1',
        authorId: 'u1',
        authorName: 'Bob',
        authorAvatarUrl: '',
        imageUrl: '',
        caption: 'Lovely',
        curationId: 'c1',
        curationTitle: 'Temple',
        likeCount: 3,
        commentCount: 0,
        createdAt: DateTime(2024, 6, 1),
      );

      final liked = post.copyWith(likeCount: 4, likedByMe: true);

      expect(liked.likeCount, 4);
      expect(liked.likedByMe, isTrue);
      expect(liked.caption, 'Lovely');
      expect(liked.commentCount, 0);
    });

    test('likedByMe defaults to false', () {
      final post = Post(
        id: 'p1',
        authorId: 'u1',
        authorName: 'X',
        authorAvatarUrl: '',
        imageUrl: '',
        caption: 'Z',
        curationId: 'c1',
        curationTitle: 'Y',
        likeCount: 1,
        commentCount: 0,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(post.likedByMe, isFalse);
    });
  });
}
