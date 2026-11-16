import 'dart:developer';
import 'package:universal_html/html.dart' as html;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/notifications/domain/repositories/notification_repository.dart';

/// Handles Firebase Cloud Messaging: permission, token lifecycle,
/// foreground heads-up banners with flutter_local_notifications, and tap routing.
///
/// On web, FCM uses VAPID (Web Push) so a [_vapidKey] must be provided.
/// On Android/iOS the native token is used directly.
class FcmService {
  FcmService(this._messaging, this._repository);

  final FirebaseMessaging _messaging;
  final NotificationRepository _repository;

  // IMPORTANT: Replace this with your actual VAPID key from
  // Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
  static const String _vapidKey =
      'BOCADYAPjTNza5guzmGGyELNxFTx0s1yg4wJcac6XL0y3t_aaZuHUhYcnka7cU7NTW32N58W-qqMHq1dK-HMyz4'; // <-- paste your key here

  static void Function(String route)? onNavigate;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _localNotificationsInitialized = false;

  /// Initializes local notifications plugin with default channel
  static Future<void> setupLocalNotifications() async {
    if (_localNotificationsInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.startsWith('doubt:')) {
            final doubtId = payload.substring(6);
            onNavigate?.call('/doubts/$doubtId');
          } else if (payload != null && payload.startsWith('holiday_approval:')) {
            final id = payload.substring(17);
            onNavigate?.call(id.isNotEmpty && id != '0'
                ? '/admin/holiday-notices/$id'
                : '/admin/holiday-notices/pending');
          } else if (payload != null && payload.startsWith('holiday_notice:')) {
            onNavigate?.call('/holiday-notices/official');
          } else if (payload != null && payload.isNotEmpty) {
            onNavigate?.call('/notifications/$payload');
          } else {
            onNavigate?.call('/notifications');
          }
        },
      );

      const androidChannel = AndroidNotificationChannel(
        'college_bridge_channel',
        'Campus Announcements',
        description: 'Notifications from College Bridge administration and teachers',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      _localNotificationsInitialized = true;
    } catch (e) {
      log('[FCM] Failed to setup local notifications: $e', name: 'FcmService');
    }
  }

  /// Call once after the user is authenticated. Requests permission, obtains
  /// the FCM token and registers it with the backend. Listens for token
  /// refreshes and message taps.
  Future<void> init() async {
    if (Firebase.apps.isEmpty) {
      log('[FCM] Firebase not initialized; skipping FCM setup.', name: 'FcmService');
      return;
    }

    // Only setup local notifications plugin on non-web (it relies on Android/iOS native channels)
    if (!kIsWeb) {
      await setupLocalNotifications();
    }

    // Request permission (Web, Android 13+, iOS).
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      log('[FCM] Notifications permission denied by user.', name: 'FcmService');
      return;
    }

    // Register current token. On web, vapidKey is required.
    final token = await _messaging.getToken(
      vapidKey: kIsWeb && _vapidKey != 'YOUR_VAPID_KEY_HERE' ? _vapidKey : null,
    );
    if (token != null) {
      await _registerToken(token);
    }

    // Keep the backend in sync when the token rotates.
    _messaging.onTokenRefresh.listen((newToken) async {
      await _registerToken(newToken);
    });

    // Handle messages received while the app is in the foreground.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle taps on notifications that opened the app from background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if the app was launched from a terminated state via a notification.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleMessageOpenedApp(initial);
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      final platform = kIsWeb
          ? 'WEB'
          : defaultTargetPlatform == TargetPlatform.iOS
              ? 'IOS'
              : 'ANDROID';
      await _repository.registerDeviceToken(
        token: token,
        platform: platform,
      );
      log('[FCM] Token registered with backend ($platform).', name: 'FcmService');
    } catch (e) {
      log('[FCM] Failed to register token: $e', name: 'FcmService');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    log('[FCM] Foreground message: ${message.data}', name: 'FcmService');
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Campus Notice';
    final body = notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';
    final doubtIdStr = message.data['doubtId']?.toString();
    final notifIdStr = message.data['notificationId']?.toString();
    final typeStr = message.data['type']?.toString();
    final noticeIdStr = (message.data['noticeId'] ?? message.data['holidayId'])?.toString() ?? '';

    String? payload;
    if (doubtIdStr != null && doubtIdStr.isNotEmpty) {
      payload = 'doubt:$doubtIdStr';
    } else if (typeStr == 'HOLIDAY_APPROVAL' || typeStr == 'HOLIDAY_DRAFT_READY') {
      payload = 'holiday_approval:$noticeIdStr';
    } else if (typeStr == 'HOLIDAY_NOTICE') {
      payload = 'holiday_notice:$noticeIdStr';
    } else {
      payload = notifIdStr;
    }

    if (kIsWeb) {
      try {
        if (html.Notification.permission == 'granted') {
          html.Notification(
            title,
            body: body,
            icon: '/icons/Icon-192.png',
          );
        }
      } catch (e) {
        log('[FCM] Web notification display error: $e', name: 'FcmService');
      }
      return;
    }

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'college_bridge_channel',
          'Campus Announcements',
          channelDescription: 'Notifications from College Bridge administration and teachers',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    log('[FCM] Opened from notification: ${message.data}', name: 'FcmService');
    final typeStr = message.data['type']?.toString();
    final noticeIdStr = (message.data['noticeId'] ?? message.data['holidayId'])?.toString() ?? '';

    if (typeStr == 'HOLIDAY_APPROVAL' || typeStr == 'HOLIDAY_DRAFT_READY') {
      onNavigate?.call(noticeIdStr.isNotEmpty && noticeIdStr != '0'
          ? '/admin/holiday-notices/$noticeIdStr'
          : '/admin/holiday-notices/pending');
      return;
    } else if (typeStr == 'HOLIDAY_NOTICE') {
      onNavigate?.call('/holiday-notices/official');
      return;
    } else if (typeStr == 'HOLIDAY_PUBLISH_FAILED') {
      onNavigate?.call('/admin/holiday-notices/$noticeIdStr');
      return;
    }

    final doubtIdStr = message.data['doubtId']?.toString();
    if (doubtIdStr != null && doubtIdStr.isNotEmpty) {
      onNavigate?.call('/doubts/$doubtIdStr');
      return;
    }
    final notifIdStr = message.data['notificationId']?.toString();
    if (notifIdStr != null && notifIdStr.isNotEmpty) {
      onNavigate?.call('/notifications/$notifIdStr');
    } else {
      onNavigate?.call('/notifications');
    }
  }

  /// Deactivates the current device token on logout.
  Future<void> deactivateToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _repository.deregisterDeviceToken(token);
      }
    } catch (e) {
      log('[FCM] Failed to deactivate token: $e', name: 'FcmService');
    }
  }
}

/// Must be a top-level function (not a class method). Registered in main.dart.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by main() before this is called.
  log('[FCM] Background message: ${message.data}', name: 'FcmService');
}
