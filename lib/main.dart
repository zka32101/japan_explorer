import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

// ── Entry point ───────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized();

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

  // FCM foreground setup (permissions, local notifications, token listener)
  await fcmService.init();

  // RevenueCat: configure anonymously — user ID is set after sign-in
  await purchaseService.configure();

  // AdMob: init once at startup; banner/interstitial creation happens
  // lazily where they're shown, gated on premium status.
  await adsService.init();

  // Hive: offline cache (must init before runApp)
  await offlineCacheService.init();

  // Hive: vision analysis cache
  final visionCacheService = VisionCacheService();
  await visionCacheService.initialize();

  // Firestore: seed culture content (force reseed in debug to pick up isPremium changes)
  final firestore = db;
  if (kDebugMode) {
    await CultureContentSeeder.forceReseed(firestore);
  } else {
    final alreadySeeded = await CultureContentSeeder.hasSeeded(firestore);
    if (!alreadySeeded) {
      await CultureContentSeeder.seedCultureContent(firestore);
    }
  }

  // Set Analytics user properties (non-PII)
  if (!kDebugMode) {
    await analyticsService.logScreenView('app_start');
  }

  // Read onboarding status synchronously before runApp so the router
  // can use it without an async gap.
  final onboardingDone = await OnboardingNotifier.loadStatus();

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
