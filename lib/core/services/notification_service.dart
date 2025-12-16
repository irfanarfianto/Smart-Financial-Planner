import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_category.dart';

// --- Background Handler (Must be Top-Level) ---
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('🌙 Background message received: ${message.messageId}');
  }
  // Note: Local Notifications are NOT shown here manually for background messages
  // because Firebase automatically shows them in system tray if "notification" payload exists.
  // We only handle data processing here if needed.
}

// --- Payload Model ---
class NotificationPayload {
  final String? route;
  final Map<String, dynamic>? data;

  NotificationPayload({this.route, this.data});

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      route: json['route'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  String toJsonString() => jsonEncode({
    if (route != null) 'route': route,
    if (data != null) 'data': data,
  });

  factory NotificationPayload.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return NotificationPayload.fromJson(json);
  }
}

// --- FCM Service ---
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Public Streams
  final _onTokenRefreshController = StreamController<String>.broadcast();
  Stream<String> get onTokenRefresh => _onTokenRefreshController.stream;

  final _onMessageOpenedController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessageOpened =>
      _onMessageOpenedController.stream;

  final _onNotificationTapController =
      StreamController<NotificationPayload?>.broadcast();
  Stream<NotificationPayload?> get onNotificationTap =>
      _onNotificationTapController.stream;

  Future<void> initialize() async {
    if (kDebugMode) print('🔔 Initializing FCM Service...');

    // 1. Request Permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      print('📱 Permission status: ${settings.authorizationStatus}');
    }

    // 2. Initialize Local Notifications
    await _initializeLocalNotifications();

    // 3. Get & Save Token
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) print('🔑 FCM Token: $token');
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Failed to get FCM token: $e');
    }

    // 4. Listeners
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _saveTokenToDatabase(token);
      _onTokenRefreshController.add(token);
    });

    // Foreground Message
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/Terminated Tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Terminated Initial Message
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Channels
    await _createChannels();
  }

  Future<void> _createChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      for (var category in NotificationCategory.values) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            category.channelId,
            category.channelName,
            description: category.channelDescription,
            importance: Importance.max,
            sound: const RawResourceAndroidNotificationSound(
              'notification_sound',
            ),
            playSound: true,
          ),
        );
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📨 Foreground: ${message.notification?.title}');
    }

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      // Determine Category from payload data
      NotificationCategory category = NotificationCategory.reminder;
      // final categoryStr = message.data['category'] as String?;

      // if (categoryStr != null) {
      //   // For now only one category exists
      //   if (categoryStr == 'reminder') category = NotificationCategory.reminder;
      // }

      final payload = NotificationPayload(
        route: message.data['route'],
        data: message.data,
      );

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: category.toAndroidDetails(
            icon: android.smallIcon ?? '@mipmap/launcher_icon',
          ),
          iOS: category.toIOSDetails(),
        ),
        payload: payload.toJsonString(),
      );
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final payload = NotificationPayload.fromJsonString(response.payload!);
        _onNotificationTapController.add(payload);
      } catch (e) {
        print('Error parsing payload: $e');
      }
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) print('🖱️ App opened by notification');
    final payload = NotificationPayload(
      route: message.data['route'],
      data: message.data,
    );
    _onNotificationTapController.add(payload);
  }

  /// Public method to manually save/update FCM token
  /// Call this after successful login/register
  Future<void> saveCurrentToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      } else {
        if (kDebugMode) print('⚠️ No FCM token available to save');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error in saveCurrentToken: $e');
    }
  }

  // --- Database Logic ---
  Future<void> _saveTokenToDatabase(String token) async {
    if (kDebugMode) print('💾 Attempting to save FCM token...');

    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      if (kDebugMode) print('⚠️ Cannot save token: User not authenticated yet');
      return;
    }

    if (kDebugMode) print('✅ User authenticated: ${user.id}');

    String? deviceName;
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Error getting device info: $e');
    }

    try {
      await _supabaseClient.from('user_devices').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'last_active_at': DateTime.now().toIso8601String(),
        'device_name': deviceName,
      }, onConflict: 'user_id, fcm_token');

      if (kDebugMode) print('✅ FCM Token saved successfully to database');
    } catch (e) {
      if (kDebugMode) print('❌ Error saving FCM token: $e');
    }
  }
}
