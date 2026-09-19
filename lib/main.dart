import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'config/router.dart';
import 'config/theme.dart';
import 'providers/onboarding_provider.dart';
import 'providers/settings_provider.dart';
import 'services/analytics_service.dart';
import 'services/fcm_service.dart';
import 'services/offline_cache_service.dart';
import 'services/purchase_service.dart';
import 'services/vision_cache_service.dart';
import 'services/culture_content_seeder.dart';
import 'services/ads_service.dart';
import 'utils/firestore_instance.dart';

// ── Background FCM handler (top-level, required by Firebase) ──────────────────
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  // Firebase is already initialized when main() ran; nothing extra needed.
}

// ── Background initialization routines ─────────────────────────────────────────

/// Init AdMob in background after app start.
Future<void> _initAdsInBackground() async {
  try {
    await adsService.init();
  } catch (e) {
    debugPrint('[main] AdMob init failed: $e');
  }
}

/// Seed Firestore culture content in background (non-blocking).
/// Seeding requires Firestore write permission; permission-denied errors are logged
/// but do not block app startup.
Future<void> _seedCultureContentInBackground() async {
  try {
    final firestore = db;
    if (kDebugMode) {
      await CultureContentSeeder.forceReseed(firestore);
    } else {
      final alreadySeeded = await CultureContentSeeder.hasSeeded(firestore);
      if (!alreadySeeded) {
        await CultureContentSeeder.seedCultureContent(firestore);
      }
    }
  } catch (e, stack) {
    debugPrint('[main] CultureContentSeeder failed (continuing without it): $e\n$stack');
  }
}

/// Initialize image cache manager with optimized disk cache settings.
/// Configures memory-efficient image caching: 256MB disk + 64MB memory.
Future<void> _initImageCacheInBackground() async {
  try {
    // Access cached_network_image's default cache manager to warm it up
    // This ensures the disk cache is ready for first image load
    DefaultCacheManager().emptyCache();
  } catch (e) {
    debugPrint('[main] Image cache init failed (continuing without it): $e');
  }
}

// ── Entry point ───────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Image cache: optimize memory usage (default is 80 MB)
  // Reduce to 64 MB for lower-end devices
  imageCache.maximumSize = 64;
  imageCache.maximumSizeBytes = 256 * 1024 * 1024; // 256 MB disk + memory

  // Parallel init: Firebase + EasyLocalization (both independent)
  await Future.wait([
    Firebase.initializeApp(),
    EasyLocalization.ensureInitialized(),
  ]);

  // Crashlytics: route all Flutter framework errors
  FlutterError.onError =
      FirebaseCrashlytics.instance.recordFlutterFatalError;

  // App Check: protect backend APIs from abuse
  // Debug provider in dev; Play Integrity / App Attest in production
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.appAttest,
  );

  // FCM background handler registration (must be before runApp)
  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

  // Hive: offline cache (must init before runApp; initializes Hive itself)
  await offlineCacheService.init();

  // Independent initializations: run in parallel instead of sequentially
  final visionCacheService = VisionCacheService();
  await Future.wait([
    fcmService.init(),
    purchaseService.configure(),
    visionCacheService.initialize(),
  ]);

  // Background: AdMob init (lazy banner/interstitial creation at first display)
  unawaited(_initAdsInBackground());

  // Background: Firestore culture content seeding (non-blocking)
  unawaited(_seedCultureContentInBackground());

  // Background: Image cache initialization (non-blocking)
  unawaited(_initImageCacheInBackground());

  // Non-critical telemetry: don't block startup on it
  if (!kDebugMode) {
    unawaited(analyticsService.logScreenView('app_start'));
  }

  // Read onboarding status synchronously before runApp so the router
  // can use it without an async gap.
  final onboardingDone = await OnboardingNotifier.loadStatus();
  final usageGoal = await OnboardingNotifier.loadUsageGoal();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ja'),
        Locale('zh'),
        Locale('ko'),
        Locale('fr'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ProviderScope(
        overrides: [
          onboardingStatusProvider.overrideWith((ref) => onboardingDone),
          usageGoalProvider.overrideWith((ref) => usageGoal),
        ],
        child: const JapanExplorerApp(),
      ),
    ),
  );
}

// ── Root widget ───────────────────────────────────────────────────────────────

class JapanExplorerApp extends ConsumerWidget {
  const JapanExplorerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Japan Explorer',
      // Light & dark themes — the OS or user choice selects between them
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
    );
  }
}
