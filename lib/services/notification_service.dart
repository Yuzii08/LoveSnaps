import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService(ref));

// ── Service ────────────────────────────────────────────────────────────────

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  // ── Initialization ─────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (kIsWeb) return;
    // Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Init local notifications (for foreground display)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel (Android 8+)
    const channel = AndroidNotificationChannel(
      'lovesnaps_main',
      'LoveSnaps',
      description: 'Couple notifications — streaks, miss you, milestones',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _ref.read(authServiceProvider).updateFcmToken(token);
    }

    // Token refresh listener
    _messaging.onTokenRefresh.listen((newToken) {
      _ref.read(authServiceProvider).updateFcmToken(newToken);
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // ── Permission Check ───────────────────────────────────────────────────

  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // ── Foreground Notifications ───────────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lovesnaps_main',
          'LoveSnaps',
          channelDescription: 'Couple notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate based on data payload — handled by app router
    debugPrint('Notification opened: ${message.data}');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
  }
}
