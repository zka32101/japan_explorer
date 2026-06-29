import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:japan_explorer/models/post.dart';
import 'package:japan_explorer/widgets/post_widget.dart';

void main() {
  final _testPost = Post(
    id: 'p1',
    authorId: 'u1',
    authorName: 'Alice',
    authorAvatarUrl: '',
    curationId: 'c1',
    curationTitle: 'Senso-ji Temple',
    caption: 'One of the most beautiful temples in Tokyo!',
    imageUrl: 'https://example.com/image.jpg',
    likeCount: 5,
    commentCount: 2,
    likedByMe: false,
    createdAt: DateTime(2024, 3, 15),
  );

  group('PostCard widget', () {
    testWidgets('renders author name and caption', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PostCard(post: _testPost),
            ),
          ),
        );

        expect(find.text('Alice'), findsOneWidget);
        expect(
            find.text('One of the most beautiful temples in Tokyo!'),
            findsOneWidget);
      });
    });

    testWidgets('renders like and comment counts', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PostCard(post: _testPost)),
          ),
        );

        expect(find.text('5'), findsWidgets);
        expect(find.text('2'), findsWidgets);
      });
    });

    testWidgets('shows avatar initial when no photo URL', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PostCard(post: _testPost)),
          ),
        );

        // Avatar initial = first letter of authorName = 'A'
        expect(find.text('A'), findsOneWidget);
      });
    });

    testWidgets('PostsSection empty state shows prompt', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PostsSection(
                posts: [],
                curationId: 'c1',
                curationTitle: 'Test',
              ),
            ),
          ),
        );

        expect(
            find.text('Be the first to share your experience!'),
            findsOneWidget);
      });
    });

    testWidgets('PostsSection shows post count in header', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PostsSection(
                posts: [_testPost, _testPost],
                curationId: 'c1',
                curationTitle: 'Test',
              ),
            ),
          ),
        );

        expect(find.text('Visitor Posts (2)'), findsOneWidget);
      });
    });
  });
}
