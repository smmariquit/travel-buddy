// Direct FCM approach without Cloud Functions
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  // Getter for FCM token
  String? get fcmToken => _fcmToken;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize Flutter Local Notifications for foreground notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    // Request permission for iOS and get token
    await _requestPermissions();

    // Get the FCM token
    await _getToken();

    // Configure Firebase Messaging handlers
    _configureFirebaseMessaging();

    _isInitialized = true;
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'trip_reminders_channel',
      'Trip Reminders',
      description: 'Notifications for upcoming trips',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    try {
      // Request notifications permission
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      debugPrint(
        'User granted notifications permission: ${settings.authorizationStatus}',
      );

      // For Android 13+
      final androidPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('Android notification permission granted: $granted');
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> _getToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $_fcmToken');
      });
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  void _configureFirebaseMessaging() {
    // Handle incoming messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message notification: ${message.notification!.title}, ${message.notification!.body}',
        );

        // Show a local notification when a message is received in foreground
        _showLocalNotification(message);
      }
    });

    // Handle notification tap when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked: ${message.data}');
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        await _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'trip_reminders_channel',
              'Trip Reminders',
              channelDescription: 'Notifications for upcoming trips',
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data['trip_id'],
        );
      }
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  // Method to update user token in Firestore
  Future<void> saveTokenToFirestore(String userId) async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      debugPrint('FCM token is null or empty, cannot save to Firestore');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(userId)
          .update({'fcmToken': _fcmToken});
      
      debugPrint('FCM token saved to Firestore for user: $userId');
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  // Show a local notification for trip reminders (without using Cloud Functions)
  Future<void> showTripReminderNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().microsecond, // Generate a unique ID
        title,
        body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'trip_reminders_channel',
            'Trip Reminders',
            channelDescription: 'Notifications for upcoming trips',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      debugPrint('Local notification sent successfully');
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }
}

Future<void> sendPushNotification({
  required String fcmToken,
  required String title,
  required String body,
}) async {
  final callable = FirebaseFunctions.instance.httpsCallable('sendPushNotification');
  try {
    final result = await callable.call({
      'token': fcmToken,
      'notification': {'title': title, 'body': body},
    });
    print('Push notification sent, response: ${result.data}');
  } catch (e) {
    print('Failed to send push notification: $e');
  }
}