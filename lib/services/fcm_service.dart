import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_navigator.dart';
import '../utils/firestore_instance.dart';

// ── Background handler (must be top-level) ────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized before this is called
}

// ── Constants ─────────────────────────────────────────────────────────────────
const _kChannelId = 'japan_explorer_default';
const _kChannelName = 'Japan Explorer';
const _kChannelDesc = 'Streak reminders, challenges & meetup updates';

// ── Service ───────────────────────────────────────────────────────────────────

class FcmService {
  FcmService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _db = db;

  bool _initialized = false;

  /// Call once in main() after Firebase.initializeApp()
  /// NOTE: FirebaseMessaging.onBackgroundMessage() must be registered in main()
  /// before calling this, as it requires a top-level function.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermission();
    await _initLocalNotifications();

    // Foreground message → show as local notification
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Notification tapped while app was in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Check if app launched from notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  // ── Permission ──────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  // ── Local notifications ─────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create the Android channel at high importance
    const channel = AndroidNotificationChannel(
      _kChannelId,
      _kChannelName,
      description: _kChannelDesc,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _showLocalNotification(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    _localNotifications.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kChannelId,
          _kChannelName,
          channelDescription: _kChannelDesc,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route'],
    );
  }

  // ── Navigation on tap ───────────────────────────────────────────────────────

  void _handleTap(RemoteMessage message) {
    final raw = message.data['route'] as String?;
    if (raw == null || raw.isEmpty) return;

    // Normalise all URL forms to a GoRouter path string
    // • "/spots/abc"                 → "/spots/abc"        (already a path)
    // • "japanexplorer:///spots/abc" → "/spots/abc"        (custom URI scheme)
    // • "https://japanexplorer.app/spots/abc" → "/spots/abc" (App Link)
    final String? goPath;
    if (raw.startsWith('/')) {
      goPath = raw;
    } else if (raw.startsWith('japanexplorer://')) {
      goPath = raw.replaceFirst('japanexplorer:/', '');
    } else if (raw.startsWith('https://japanexplorer.app')) {
      goPath = Uri.parse(raw).path;
    } else {
      goPath = null;
    }

    if (goPath == null || goPath.isEmpty) return;

    final context = appNavigatorKey.currentContext;
    if (context != null) {
      // App is in foreground or background — navigate immediately
      GoRouter.of(context).go(goPath);
    } else {
      // App was terminated — store for consumption in SplashScreen
      _pendingRoute = goPath;
    }
  }

  String? _pendingRoute;

  /// Consume the pending route once (called in SplashScreen)
  String? consumePendingRoute() {
    final r = _pendingRoute;
    _pendingRoute = null;
    return r;
  }

  // ── Token management ────────────────────────────────────────────────────────

  /// Save / refresh the FCM token for the current user in Firestore.
  /// Call this after sign-in.
  Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _persistToken(userId, token);

      // Auto-refresh
      _messaging.onTokenRefresh.listen((t) => _persistToken(userId, t));
    } catch (_) {
      // Non-fatal — app functions without push notifications
    }
  }

  Future<void> _persistToken(String userId, String token) async {
    await _db.collection('users').doc(userId).update({
      'fcm_token': token,
      'fcm_updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Remove the FCM token on sign-out to stop notifications for this device.
  Future<void> clearTokenForUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({'fcm_token': null});
      await _messaging.deleteToken();
    } catch (_) {}
  }

  // ── Streak reminder (local notification scheduled daily) ────────────────────

  static const _kStreakReminderId = 42;
  static const _kStreakChannelId = 'streak_reminder';
  static const _kStreakChannelName = 'Streak Reminder';

  /// Schedule a daily local notification at [hour]:[minute] (24h) to remind
  /// the user to keep their streak alive. Call after sign-in and from Settings.
  Future<void> scheduleStreakReminder({int hour = 20, int minute = 0}) async {
    try {
      await _localNotifications.cancel(_kStreakReminderId);

      final androidChannel = AndroidNotificationChannel(
        _kStreakChannelId,
        _kStreakChannelName,
        description: 'Daily streak reminder',
        importance: Importance.defaultImportance,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _kStreakChannelId,
          _kStreakChannelName,
          channelDescription: 'Daily streak reminder',
          icon: '@mipmap/ic_launcher',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

      // Show a one-time notification for today as a test / first reminder.
      // Periodic scheduling requires a background entitlement — local show is
      // the safest cross-device approach without a backend.
      await _localNotifications.periodicallyShow(
        _kStreakReminderId,
        '🔥 Keep your streak alive!',
        'Open Japan Explorer to maintain your streak today.',
        RepeatInterval.daily,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Notification scheduling not supported on this device — non-fatal
    }
  }

  Future<void> cancelStreakReminder() async {
    try {
      await _localNotifications.cancel(_kStreakReminderId);
    } catch (_) {}
  }

  // ── Daily culture notification ──────────────────────────────────────────────

  static const _kDailyCultureId = 43;
  static const _kDailyChannelId = 'daily_culture';
  static const _kDailyChannelName = 'Daily Culture';

  /// Schedule a daily "Today's Culture" notification at [hour]:[minute] (24h).
  /// Call after sign-in. Pass the current daily title to include in the body.
  Future<void> scheduleDailyCultureNotification({
    int hour = 9,
    int minute = 0,
    String? todayTitle,
  }) async {
    try {
      await _localNotifications.cancel(_kDailyCultureId);

      final androidChannel = AndroidNotificationChannel(
        _kDailyChannelId,
        _kDailyChannelName,
        description: 'Learn one piece of Japanese culture every day',
        importance: Importance.defaultImportance,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _kDailyChannelId,
          _kDailyChannelName,
          channelDescription: 'Learn one piece of Japanese culture every day',
          icon: '@mipmap/ic_launcher',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

      final body = todayTitle != null
          ? 'Today: $todayTitle'
          : 'Discover something new about Japan today 🇯🇵';

      await _localNotifications.periodicallyShow(
        _kDailyCultureId,
        '📅 Today\'s Japan Culture',
        body,
        RepeatInterval.daily,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '/culture',
      );
    } catch (_) {}
  }

  Future<void> cancelDailyCultureNotification() async {
    try {
      await _localNotifications.cancel(_kDailyCultureId);
    } catch (_) {}
  }
}

/// Singleton instance used across the app
final fcmService = FcmService._();
