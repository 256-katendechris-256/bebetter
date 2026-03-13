import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

// ─── Must match AndroidManifest meta-data value ───────────────────────────────
const _kChannelId   = 'bud_bookclub_channel';
const _kChannelName = 'BookClub Notifications';
const _kChannelDesc = 'Streak alerts, league updates, reading reminders';

// ─── Background handler — must be top-level ──────────────────────────────────
// DO NOT call show() here — FCM auto-displays the notification when app is
// background/closed because our messages include a `notification` key.
// Calling show() here causes duplicates (FCM shows 1 + we show another).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background FCM: ${message.notification?.title}');
  // FCM handles display automatically — nothing to do here.
}

// ═════════════════════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE
// ═════════════════════════════════════════════════════════════════════════════

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging   = FirebaseMessaging.instance;
  final _localNotifs = FlutterLocalNotificationsPlugin();

  // Callback set from main.dart to navigate to inbox on tap
  VoidCallback? onNotificationTap;

  static const _channel = AndroidNotificationChannel(
    _kChannelId,
    _kChannelName,
    description    : _kChannelDesc,
    importance     : Importance.max,
    playSound      : true,
    enableVibration: true,
  );

  Future<void> init() async {
    // 1. Register background handler FIRST
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permission
    final settings = await _messaging.requestPermission(
      alert      : true,
      badge      : true,
      sound      : true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // 3. iOS foreground presentation
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Create Android channel — id must match _kChannelId + manifest
    await _localNotifs
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 5. Init local notifications (foreground only)
    await _localNotifs.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onLocalNotifTap,
    );

    // 6. Register FCM token
    await _registerToken();

    // 7. Refresh token listener
    _messaging.onTokenRefresh.listen(_sendTokenToBackend);

    // 8. FOREGROUND messages — must show manually (FCM doesn't auto-display
    //    when app is open on Android)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 9. App opened from background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 10. Cold start — app was fully closed when notification was tapped
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  // ── Token registration ─────────────────────────────────────────────────────

  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('❌ FCM token registration failed: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await ApiService().registerFCMToken(token);
      debugPrint('✅ FCM token sent to backend');
    } catch (e) {
      debugPrint('❌ Failed to send FCM token: $e');
    }
  }

  // ── Foreground handler ─────────────────────────────────────────────────────
  // Only called when app is OPEN. Background/closed is handled by FCM itself.

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground: ${message.notification?.title}');
    final n = message.notification;
    if (n == null) return;

    _localNotifs.show(
      message.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kChannelId,
          _kChannelName,
          channelDescription: _kChannelDesc,
          importance        : Importance.max,
          priority          : Priority.high,
          icon              : '@mipmap/ic_launcher',
          playSound         : true,
          enableVibration   : true,
        ),
      ),
      payload: message.data['type'],
    );
  }

  // ── Tap handlers ───────────────────────────────────────────────────────────

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Tapped: ${message.data}');
    _navigateToInbox();
  }

  void _onLocalNotifTap(NotificationResponse response) {
    debugPrint('🔔 Local tapped: ${response.payload}');
    _navigateToInbox();
  }

  void _navigateToInbox() => onNotificationTap?.call();

  // ── Unregister on logout ───────────────────────────────────────────────────

  Future<void> unregisterToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await ApiService().unregisterFCMToken(token);
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM unregister failed: $e');
    }
  }
}