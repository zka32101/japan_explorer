import 'package:easy_localization/easy_localization.dart';
import '../screens/stamp_book_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/favorites_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../screens/ai_planner_screen.dart';
import '../screens/camera_history_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/challenge_screen.dart';
import '../screens/collection_screen.dart';
import '../screens/community_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/culture_detail_screen.dart';
import '../screens/culture_hub_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/host_discovery_screen.dart';
import '../screens/host_profile_screen.dart';
import '../screens/invite_friends_screen.dart';
import '../screens/journal_entry_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/login_screen.dart';
import '../screens/map_screen.dart';
import '../screens/menu_translator_screen.dart';
import '../screens/myplan_screen.dart';
import '../screens/offline_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/phrases_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/premium_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/ranking_screen.dart';
import '../screens/search_screen.dart';
import '../screens/season_events_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/vision_cache_history_screen.dart';
import '../screens/what_is_this_screen.dart';
import '../services/analytics_service.dart';
import '../utils/app_navigator.dart';
import '../utils/constants.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/offline_banner.dart';
import '../widgets/theme/app_icons.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final isOnboardingDone = ref.watch(onboardingStatusProvider);

  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: AppRoutes.splash,
    observers: [AppAnalyticsObserver()],
    redirect: (context, state) {
      if (authState.isLoading) return null;

      // Splash controls its own navigation — never redirect away from it
      if (state.matchedLocation == AppRoutes.splash) return null;

      final isLoggedIn = authState.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );

      final loc = state.matchedLocation;
      final isLoginRoute = loc == AppRoutes.login;
      final isOnboardingRoute = loc == AppRoutes.onboarding;

      // Not logged in → always require login
      if (!isLoggedIn && !isLoginRoute) return AppRoutes.login;

      // Logged in on login page → decide next step
      if (isLoggedIn && isLoginRoute) {
        return isOnboardingDone ? AppRoutes.home : AppRoutes.onboarding;
      }

      // Logged in on onboarding page but already done → home
      if (isLoggedIn && isOnboardingRoute && isOnboardingDone) {
        return AppRoutes.home;
      }

      // Logged in, not on onboarding, but not done → force onboarding
      if (isLoggedIn && !isOnboardingRoute && !isOnboardingDone) {
        return AppRoutes.onboarding;
      }

      return null;
    },
    routes: [
      // Splash (entry point)
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.camera,
        builder: (context, state) => const CameraScreen(),
        routes: [
          GoRoute(
            path: 'history',
            builder: (context, state) => const CameraHistoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.phrases,
        builder: (context, state) => const PhrasesScreen(),
      ),
      GoRoute(
        path: AppRoutes.challenge,
        builder: (context, state) => const ChallengeScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiPlanner,
        builder: (context, state) => const AiPlannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.progress,
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: AppRoutes.hosts,
        builder: (context, state) => const HostDiscoveryScreen(),
        routes: [
          GoRoute(
            path: ':uid',
            builder: (context, state) => HostProfileScreen(
              hostUid: state.pathParameters['uid']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.premium,
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: AppRoutes.stamps,
        builder: (context, state) => const StampBookScreen(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.inviteFriends,
        builder: (context, state) => const InviteFriendsScreen(),
      ),
      GoRoute(
        path: AppRoutes.seasonEvents,
        builder: (context, state) => const SeasonEventsScreen(),
      ),
      GoRoute(
        path: AppRoutes.offlineContent,
        builder: (context, state) => const OfflineScreen(),
      ),
      GoRoute(
        path: AppRoutes.journal,
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.journalEntry}/:id',
        builder: (context, state) => JournalEntryScreen(
          entryId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.whatIsThis,
        builder: (context, state) => const WhatIsThisScreen(),
      ),
      GoRoute(
        path: AppRoutes.menuTranslator,
        builder: (context, state) => const MenuTranslatorScreen(),
      ),
      GoRoute(
        path: AppRoutes.visionCacheHistory,
        builder: (context, state) => const VisionCacheHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.cultureHub,
        builder: (context, state) => const CultureHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.collection,
        builder: (context, state) => const CollectionScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.cultureDetail}',
        builder: (context, state) => CultureDetailScreen(
          contentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.createPost,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.postDetail}/:id',
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MainShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'detail/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return DetailScreen(curationId: id);
                },
              ),
              GoRoute(
                path: 'ranking',
                builder: (context, state) => const RankingScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.myPlan,
            builder: (context, state) => const MyPlanScreen(),
          ),
          GoRoute(
            path: AppRoutes.map,
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: AppRoutes.community,
            builder: (context, state) => const CommunityScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatefulWidget {
  final Widget child;

  /// Current route path; keeps the selected tab in sync with deep links,
  /// back navigation and `context.go` calls made outside the tab bar.
  final String location;
  const MainShell({super.key, required this.child, required this.location});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Bottom tabs, left to right. Search is reached from the Home search field
  // (it stays under the shell so the bar remains visible) and counts as Home.
  final _routes = [
    AppRoutes.home,
    AppRoutes.map,
    AppRoutes.myPlan,
    AppRoutes.community,
    AppRoutes.profile,
  ];

  int? _indexFor(String location) {
    if (location == AppRoutes.search) return 0;
    for (var i = 0; i < _routes.length; i++) {
      final r = _routes[i];
      if (location == r || location.startsWith('$r/')) return i;
    }
    return null; // e.g. /map: keep the previously selected tab
  }

  @override
  Widget build(BuildContext context) {
    _currentIndex = _indexFor(widget.location) ?? _currentIndex;
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: widget.child),
          const BannerAdWidget(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        // 「コミュニティ」「プロフィール」など長いラベルが2行に折り返さないよう小さめにする
        data: NavigationBarTheme.of(context).copyWith(
          labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
        ),
        child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          context.go(_routes[index]);
        },
        destinations: [
          NavigationDestination(
            icon: const AppIcon(AppGlyph.home),
            selectedIcon: const AppIcon(AppGlyph.home, strokeWidth: 2.6),
            label: tr('nav.home'),
          ),
          NavigationDestination(
            icon: const AppIcon(AppGlyph.map),
            selectedIcon: const AppIcon(AppGlyph.map, strokeWidth: 2.6),
            label: tr('nav.map'),
          ),
          NavigationDestination(
            icon: const AppIcon(AppGlyph.plan),
            selectedIcon: const AppIcon(AppGlyph.plan, strokeWidth: 2.6),
            label: tr('nav.my_plan'),
          ),
          NavigationDestination(
            icon: const AppIcon(AppGlyph.people),
            selectedIcon: const AppIcon(AppGlyph.people, strokeWidth: 2.6),
            label: tr('nav.community'),
          ),
          NavigationDestination(
            icon: const AppIcon(AppGlyph.me),
            selectedIcon: const AppIcon(AppGlyph.me, strokeWidth: 2.6),
            label: tr('nav.profile'),
          ),
        ],
      ),
      ),
    );
  }
}
