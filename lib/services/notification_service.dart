import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

// Global navigator key — set this in main.dart on MaterialApp
final GlobalKey<NavigatorState> notificationNavigatorKey = GlobalKey<NavigatorState>();

// ─── Background handler — must be top-level ──────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging   = FirebaseMessaging.instance;
  final _localNotifs = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'bookclub_high',
    'BookClub Notifications',
    description: 'Streak alerts, league updates, reading reminders',
    importance : Importance.high,
  );

  Future<void> init() async {
    // 1. Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permission
    final settings = await _messaging.requestPermission(
      alert    : true,
      badge    : true,
      sound    : true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // 3. Create Android notification channel — generic on same line, no semicolon break
    await _localNotifs
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Init local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifs.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 5. Register FCM token with Django
    await _registerToken();

    // 6. Token refresh
    _messaging.onTokenRefresh.listen(_sendTokenToBackend);

    // 7. Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 8. App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 9. Cold start from notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _sendTokenToBackend(token);
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final api = ApiService();
      await api.registerFCMToken(token);
      debugPrint('FCM token registered with backend');
    } catch (e) {
      debugPrint('Failed to send token to backend: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifs.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority  : Priority.high,
          icon      : '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['type'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped — type: ${message.data['type']}');
    _navigateToInbox();
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped — payload: ${response.payload}');
    _navigateToInbox();
  }

  void _navigateToInbox() {
    if (onNotificationTap != null) {
      onNotificationTap!();
    }
  }

  // Set this callback from main.dart / Dashboard to handle navigation
  VoidCallback? onNotificationTap;

  String? _pendingRoute;
  String? consumePendingRoute() {
    final route  = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  Future<void> unregisterToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final api = ApiService();
        await api.unregisterFCMToken(token);
      }
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM unregister failed: $e');
    }
  }
}