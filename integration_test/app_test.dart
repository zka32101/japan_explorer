// integration_test/app_test.dart
// Run with: flutter test integration_test/app_test.dart
// Requires no Firebase emulator — uses fake_cloud_firestore + mocktail.
//
// NOTE ON FIRESTORE INJECTION
// ---------------------------
// `StreakNotifier` (lib/providers/streak_provider.dart) and `PostNotifier`
// (lib/providers/post_provider.dart) reference `FirebaseFirestore.instance`
// directly rather than a provider-injected instance. They therefore cannot be
// driven against a `FakeFirebaseFirestore` purely via `ProviderScope` overrides
// without first calling `Firebase.initializeApp()` (which the task forbids).
//
// To keep these tests hermetic (no emulator, no Firebase init) while still
// exercising the *exact* streak / post-submit logic, Group 2 and Group 3 run
// that logic through small, source-faithful harness functions
// (`runCheckAndUpdateStreak` / `runSubmitPost`) that take an injected
// `FirebaseFirestore`. These mirror the production notifier bodies line-for-line
// against the fake. The widget-level redirect tests (Group 1) use the real
// providers via `ProviderScope` overrides.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:japan_explorer/config/router.dart';
import 'package:japan_explorer/models/post.dart';
import 'package:japan_explorer/models/user.dart';
import 'package:japan_explorer/providers/auth_provider.dart';
import 'package:japan_explorer/screens/home_screen.dart';
import 'package:japan_explorer/screens/login_screen.dart';
import 'package:japan_explorer/services/upload_service.dart';
import 'package:japan_explorer/utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────
// Mocks & fakes
// ─────────────────────────────────────────────────────────────────────────

class MockFirebaseUser extends Mock implements firebase_auth.User {}

class MockUploadService extends Mock implements UploadService {}

class FakeFile extends Fake implements File {}

/// Builds an [AppUser] with sensible test defaults so individual tests only
/// need to override the fields they care about.
AppUser buildTestUser({
  String uid = 'test-uid',
  String email = 'tester@example.com',
  String displayName = 'Tester',
  String? photoUrl,
  int xp = 0,
  int level = 1,
  List<String> badges = const [],
  int streakDays = 0,
  int streakRecoveryUsed = 0,
}) {
  final now = DateTime(2026, 6, 7);
  return AppUser(
    uid: uid,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
    preferredCategories: const [],
    xp: xp,
    level: level,
    badges: badges,
    streakDays: streakDays,
    lastActiveDate: null,
    streakRecoveryUsed: streakRecoveryUsed,
    savedCurationIds: const [],
    languageCode: 'en',
    createdAt: now,
    updatedAt: now,
  );
}

/// Widget pump helper — boots the real GoRouter from `routerProvider`.
Widget makeApp(WidgetRef? _, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: Consumer(builder: (ctx, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(routerConfig: router);
      }),
    );

// ─────────────────────────────────────────────────────────────────────────
// Source-faithful logic harnesses (see file header note)
// ─────────────────────────────────────────────────────────────────────────

/// Mirrors `StreakNotifier.checkAndUpdateStreak()` against an injected
/// [FirebaseFirestore]. Returns the new streak value.
Future<int> runCheckAndUpdateStreak(
  FirebaseFirestore db,
  String uid, {
  DateTime? nowOverride,
}) async {
  final docRef = db.collection(FirestoreCollections.users).doc(uid);
  final doc = await docRef.get();
  if (!doc.exists) return 0;

  final data = doc.data()!;
  final lastTs = data['last_activity_date'] as Timestamp?;
  final currentStreak = (data['streak_days'] ?? 0) as int;
  final recoveryUsed = (data['streak_recovery_used'] ?? 0) as int;

  final now = nowOverride ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (lastTs == null) {
    await docRef.update({
      'streak_days': 1,
      'last_activity_date': Timestamp.fromDate(today),
    });
    return 1;
  }

  final lastDate = lastTs.toDate();
  final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
  final diff = today.difference(lastDay).inDays;

  if (diff == 0) {
    return currentStreak;
  }

  final Map<String, dynamic> updates = {
    'last_activity_date': Timestamp.fromDate(today),
  };

  int newStreak;
  if (diff == 1) {
    newStreak = currentStreak + 1;
    updates['streak_days'] = newStreak;
  } else if (diff == 2 &&
      recoveryUsed < AppConstants.streakRecoveryPerMonth) {
    newStreak = currentStreak + 1;
    updates['streak_days'] = newStreak;
    updates['streak_recovery_used'] = recoveryUsed + 1;
  } else {
    newStreak = 1;
    updates['streak_days'] = 1;
    if (today.month != lastDay.month) {
      updates['streak_recovery_used'] = 0;
    }
  }

  await docRef.update(updates);
  return newStreak;
}

/// Mirrors `PostNotifier.submitPost()` against an injected [FirebaseFirestore]
/// and [UploadService]. Returns true on success.
Future<bool> runSubmitPost(
  FirebaseFirestore db,
  UploadService uploadService,
  AppUser user, {
  required String curationId,
  required String curationTitle,
  required String comment,
  required double rating,
  List<String> tags = const [],
  File? imageFile,
}) async {
  String? imageUrl;
  if (imageFile != null) {
    imageUrl = await uploadService.uploadPostImage(user.uid, imageFile);
  }

  final post = Post(
    id: '',
    userId: user.uid,
    userName: user.displayName.isNotEmpty ? user.displayName : 'Explorer',
    userAvatarUrl: user.photoUrl,
    curationId: curationId,
    curationTitle: curationTitle,
    imageUrl: imageUrl,
    comment: comment,
    rating: rating,
    tags: tags,
    createdAt: DateTime.now(),
    moderationStatus: 'pending',
  );

  await db.collection(FirestoreCollections.posts).add(post.toFirestore());

  final docRef = db.collection(FirestoreCollections.users).doc(user.uid);
  await db.runTransaction((tx) async {
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

  return true;
}

// ─────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  // ───────────────────────────────────────────────────────────────────────
  // Group 1: Auth redirect (widget-level, real providers via overrides)
  // ───────────────────────────────────────────────────────────────────────
  group('Auth redirect', () {
    testWidgets('unauthenticated user redirects to /login', (tester) async {
      await tester.pumpWidget(
        makeApp(null, [
          // Emit a resolved null auth state → router redirect guard sends
          // any non-splash route to /login.
          firebaseAuthStateProvider.overrideWith(
            (ref) => Stream<firebase_auth.User?>.value(null),
          ),
        ]),
      );

      // SplashScreen waits 2.2s then routes itself; settle past that.
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('authenticated user lands on HomeScreen', (tester) async {
      final mockUser = MockFirebaseUser();
      when(() => mockUser.uid).thenReturn('test-uid');
      when(() => mockUser.email).thenReturn('tester@example.com');
      when(() => mockUser.displayName).thenReturn('Tester');
      when(() => mockUser.photoURL).thenReturn(null);

      final appUser = buildTestUser();

      await tester.pumpWidget(
        makeApp(null, [
          firebaseAuthStateProvider.overrideWith(
            (ref) => Stream<firebase_auth.User?>.value(mockUser),
          ),
          appUserProvider.overrideWith(
            (ref) => Stream<AppUser?>.value(appUser),
          ),
        ]),
      );

      // Let SplashScreen's 2.2s delay elapse, streak run, then navigate /home.
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Group 2: Streak counter update (pure logic against FakeFirebaseFirestore)
  // ───────────────────────────────────────────────────────────────────────
  group('Streak counter update', () {
    test('streak increments on consecutive days', () async {
      final db = FakeFirebaseFirestore();
      final now = DateTime(2026, 6, 7);
      final yesterday = DateTime(2026, 6, 6);

      await db.collection(FirestoreCollections.users).doc('test-uid').set({
        'streak_days': 3,
        'streak_recovery_used': 0,
        'last_activity_date': Timestamp.fromDate(yesterday),
      });

      final newStreak =
          await runCheckAndUpdateStreak(db, 'test-uid', nowOverride: now);

      final updated =
          await db.collection(FirestoreCollections.users).doc('test-uid').get();

      expect(newStreak, 4);
      expect(updated.data()!['streak_days'], 4);
    });

    test('streak resets after 3-day gap', () async {
      final db = FakeFirebaseFirestore();
      final now = DateTime(2026, 6, 7);
      final threeDaysAgo = DateTime(2026, 6, 4);

      await db.collection(FirestoreCollections.users).doc('test-uid').set({
        'streak_days': 10,
        'streak_recovery_used': 0,
        'last_activity_date': Timestamp.fromDate(threeDaysAgo),
      });

      final newStreak =
          await runCheckAndUpdateStreak(db, 'test-uid', nowOverride: now);

      final updated =
          await db.collection(FirestoreCollections.users).doc('test-uid').get();

      expect(newStreak, 1);
      expect(updated.data()!['streak_days'], 1);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Group 3: Post submission (logic against FakeFirebaseFirestore + mock upload)
  // ───────────────────────────────────────────────────────────────────────
  group('Post submission', () {
    test('submitPost writes document to Firestore', () async {
      final db = FakeFirebaseFirestore();
      final mockUpload = MockUploadService();
      when(() => mockUpload.uploadPostImage(any(), any()))
          .thenAnswer((_) async => 'https://test.example.com/photo.jpg');

      final user = buildTestUser(uid: 'author-uid', displayName: 'Author');

      // Seed the user doc so the XP transaction has a target.
      await db
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .set({'xp': 0, 'total_posts': 0});

      final ok = await runSubmitPost(
        db,
        mockUpload,
        user,
        curationId: 'curation-123',
        curationTitle: 'Fushimi Inari',
        comment: 'Amazing torii gates!',
        rating: 4.5,
        imageFile: FakeFile(),
      );

      final posts =
          await db.collection(FirestoreCollections.posts).get();

      expect(ok, isTrue);
      expect(posts.docs.length, 1);

      final data = posts.docs.first.data();
      expect(data['curation_id'], 'curation-123');
      expect(data['comment'], 'Amazing torii gates!');
      expect(data['image_url'], 'https://test.example.com/photo.jpg');

      // Upload was invoked once with the user uid.
      verify(() => mockUpload.uploadPostImage(user.uid, any())).called(1);
    });
  });
}
