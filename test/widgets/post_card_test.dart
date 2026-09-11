import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:japan_explorer/models/post.dart';
import 'package:japan_explorer/widgets/post_widget.dart';

/// Wraps [child] with the EasyLocalization ancestor so `.tr()` calls in the
/// widget tree resolve to real strings from assets/translations/en.json
/// instead of throwing or falling through to the raw key.
///
/// All assertions below live in a single `testWidgets` block and swap
/// widget trees via repeated `pumpWidget` — EasyLocalizationController is a
/// process-wide singleton whose "loaded" state doesn't reliably reset
/// between separate `testWidgets` blocks in the same file.
Widget _localizedApp(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('en')],
    fallbackLocale: const Locale('en'),
    path: 'assets/translations',
    child: Builder(
      builder: (context) => MaterialApp(
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final testPost = Post(
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
    testWidgets('renders card content, counts, avatar, and section header',
        (tester) async {
      await mockNetworkImagesFor(() async {
        // -- author name + caption --
        await tester.pumpWidget(_localizedApp(PostCard(post: testPost)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Alice'), findsOneWidget);
        expect(
            find.text('One of the most beautiful temples in Tokyo!'),
            findsOneWidget);

        // -- like/comment counts --
        expect(find.text('5'), findsWidgets);
        expect(find.text('2'), findsWidgets);

        // -- avatar initial when no photo URL --
        expect(find.text('A'), findsOneWidget);

        // -- PostsSection empty state --
        await tester.pumpWidget(_localizedApp(const PostsSection(
          posts: [],
          curationId: 'c1',
          curationTitle: 'Test',
        )));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Be the first to share your experience!'),
            findsOneWidget);

        // -- PostsSection header shows post count --
        // Two full PostCards overflow the default 600px test viewport height
        // — widen it so nothing off-screen gets treated as a render error.
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_localizedApp(PostsSection(
          posts: [testPost, testPost],
          curationId: 'c1',
          curationTitle: 'Test',
        )));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Visitor Posts (2)'), findsOneWidget);
      });
    });
  });
}
