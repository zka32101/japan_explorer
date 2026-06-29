import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _logger = Logger();

  static Future<void> initialize(String? userId) async {
    // 通知許可リクエスト
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ローカル通知の初期化
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // FCMトークンをFirestoreに保存
    if (userId != null) {
      await _saveFcmToken(userId);
    }

    // フォアグラウンドメッセージ受信
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // バックグラウンドからの起動
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Daily Phraseトピック購読
    await _messaging.subscribeToTopic('daily_phrase');
  }

  static Future<void> _saveFcmToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcm_token': token,
        'fcm_token_updated': FieldValue.serverTimestamp(),
      });
      _logger.i('FCM token saved');

      // トークン更新時に再保存
      _messaging.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcm_token': newToken});
      });
    } catch (e) {
      _logger.w('FCM token save failed: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'japan_explorer',
          'Japan Explorer',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    _logger.i('Notification tapped: ${data['type']}');
    // ナビゲーション処理はルーターで行う
  }

  static Future<void> unsubscribeAll() async {
    await _messaging.unsubscribeFromTopic('daily_phrase');
    await _messaging.deleteToken();
  }
}
