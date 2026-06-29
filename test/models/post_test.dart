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
        userId: 'user1',
        userName: 'Taro',
        curationId: 'spot42',
        curationTitle: 'Fushimi Inari',
        comment: 'Amazing shrine!',
        rating: 4.5,
        tags: const ['⛩️ Shrine', '📸 Photo Spot'],
        createdAt: DateTime(2024, 1, 1),
        moderationStatus: 'approved',
      );

      final ref = await fakeFirestore
          .collection('posts')
          .add(post.toFirestore());
      final doc = await ref.get();
      final restored = Post.fromFirestore(doc);

      expect(restored.userId, 'user1');
      expect(restored.userName, 'Taro');
      expect(restored.curationId, 'spot42');
      expect(restored.curationTitle, 'Fushimi Inari');
      expect(restored.comment, 'Amazing shrine!');
      expect(restored.rating, 4.5);
      expect(restored.tags, ['⛩️ Shrine', '📸 Photo Spot']);
      expect(restored.moderationStatus, 'approved');
    });

    test('fromFirestore uses defaults for missing fields', () async {
      final ref = await fakeFirestore.collection('posts').add({
        'user_id': 'u1',
        'user_name': 'Jane',
        'curation_id': 'c1',
        'curation_title': 'Spot',
        'comment': 'Nice',
        // rating, tags, moderation_status intentionally omitted
      });
      final doc = await ref.get();
      final post = Post.fromFirestore(doc);

      expect(post.rating, 0.0);
      expect(post.tags, isEmpty);
      expect(post.moderationStatus, 'pending');
      expect(post.imageUrl, isNull);
      expect(post.userAvatarUrl, isNull);
    });

    test('toFirestore omits null optional fields', () {
      final post = Post(
        id: '',
        userId: 'u1',
        userName: 'Bob',
        curationId: 'c1',
        curationTitle: 'Temple',
        comment: 'Lovely',
        rating: 3.0,
        createdAt: DateTime(2024, 6, 1),
        // imageUrl and userAvatarUrl intentionally null
      );
      final map = post.toFirestore();

      expect(map.containsKey('image_url'), isFalse);
      expect(map.containsKey('user_avatar_url'), isFalse);
      expect(map['comment'], 'Lovely');
      expect(map['rating'], 3.0);
    });

    test('pending is the default moderation status', () {
      final post = Post(
        id: '',
        userId: 'u1',
        userName: 'X',
        curationId: 'c1',
        curationTitle: 'Y',
        comment: 'Z',
        rating: 1.0,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(post.moderationStatus, 'pending');
    });
  });
}
