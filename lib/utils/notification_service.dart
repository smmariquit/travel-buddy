// Direct FCM approach without Cloud Functions
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late TwilioFlutter twilioFlutter;

  bool _isInitialized = false;
  String? _fcmToken;

  // Getter for FCM token
  String? get fcmToken => _fcmToken;

  // Format phone number to Twilio format (+63xxxxxxxxxx)
  String? formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If empty or too short, return null
    if (digitsOnly.isEmpty || digitsOnly.length < 10) {
      return null;
    }

    // If number starts with 0, replace with 63
    if (digitsOnly.startsWith('0')) {
      digitsOnly = '63' + digitsOnly.substring(1);
    }

    // If number starts with 9, add 63
    if (digitsOnly.startsWith('9')) {
      digitsOnly = '63' + digitsOnly;
    }

    // If number doesn't start with 63, add it
    if (!digitsOnly.startsWith('63')) {
      digitsOnly = '63' + digitsOnly;
    }

    // Validate final length (should be 12 digits: 63 + 10 digits)
    if (digitsOnly.length != 12) {
      return null;
    }

    // Add + prefix
    return '+$digitsOnly';
  }

  Future<void> addNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    required bool isRead,
  }) async {
    await FirebaseFirestore.instance
        .collection('appUsers')
        .doc(userId)
        .collection('notifications')
        .add({
          "title": title,
          "body": body,
          "type": type,
          "read": isRead,
          "timestamp": FieldValue.serverTimestamp(),
        });
  }

  /// Mark a notification as read in Firestore
  Future<void> markNotificationAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await FirebaseFirestore.instance
        .collection('appUsers')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Fetch all notifications for a user, ordered by timestamp descending
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('appUsers')
            .doc(userId)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Format notification message with emojis and branding
  String formatNotificationMessage(String title, String body) {
    return '''
🚀 TravelBuddy
━━━━━
${title}

${body}
━━━━━
Safe travels! ✈️''';
  }

  // Send WhatsApp message with error handling
  Future<void> sendWhatsAppMessage(
    String phoneNumber,
    String title,
    String body,
  ) async {
    try {
      final formattedNumber = formatPhoneNumber(phoneNumber);
      if (formattedNumber == null) {
        debugPrint(
          'Invalid phone number format, skipping WhatsApp notification',
        );
        return;
      }

      debugPrint('Sending WhatsApp message to: $formattedNumber');

      TwilioResponse response = await twilioFlutter.sendWhatsApp(
        toNumber: formattedNumber,
        messageBody: formatNotificationMessage(title, body),
      );
      debugPrint('Twilio message sent successfully: ${response.toString()}');
    } catch (e) {
      debugPrint('Error sending Twilio message: $e');
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;

    twilioFlutter = TwilioFlutter(
      accountSid: 'ACa6cfdca8cf8927d69fda634125c3d138',
      authToken: 'b2ad8ed6fc74654884123560e2fb3bfb',
      twilioNumber: '+14155238886',
    );

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

    // Get user's phone number from Firestore
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('appUsers')
                .doc(userId)
                .get();

        final phoneNumber = userDoc.data()?['phoneNumber'] as String?;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          await sendWhatsAppMessage(phoneNumber, '🎯 Trip Reminder', body);
        }
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp notification: $e');
    }

    try {
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().microsecond,
        '🎯 Trip Reminder',
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

    // Save to Firestore
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await addNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        type: 'trip_reminder',
        isRead: false,
      );
    }
  }

  // Show a friend request accepted notification
  Future<void> showFriendRequestAcceptedNotification({
    required String friendName,
    String? friendId,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    // Get user's phone number from Firestore
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('appUsers')
                .doc(userId)
                .get();

        final phoneNumber = userDoc.data()?['phoneNumber'] as String?;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          await sendWhatsAppMessage(
            phoneNumber,
            '✅ Friend Request Accepted',
            'You accepted $friendName\'s friend request. You can now plan trips together! 🎉',
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp notification: $e');
    }

    try {
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().microsecond,
        '✅ Friend Request Accepted',
        'You accepted $friendName\'s friend request. You can now plan trips together! 🎉',
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'friend_requests_channel',
            'Friend Requests',
            channelDescription: 'Notifications for friend request activities',
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
        payload: friendId,
      );
      debugPrint('Friend request accepted notification sent successfully');
    } catch (e) {
      debugPrint('Error showing friend request accepted notification: $e');
    }

    // Save to Firestore
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await addNotificationToUser(
        userId: userId,
        title: 'Friend Request Accepted',
        body:
            'You accepted $friendName\'s friend request. You can now plan trips together! 🎉',
        type: 'friend_request_accepted',
        isRead: false,
      );
    }
  }

  // Show a friend request rejected notification
  Future<void> showFriendRequestRejectedNotification({
    required String friendName,
    String? friendId,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    // Get user's phone number from Firestore
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('appUsers')
                .doc(userId)
                .get();

        final phoneNumber = userDoc.data()?['phoneNumber'] as String?;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          await sendWhatsAppMessage(
            phoneNumber,
            '❌ Friend Request Rejected',
            'You rejected $friendName\'s friend request.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp notification: $e');
    }

    try {
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().microsecond,
        '❌ Friend Request Rejected',
        'You rejected $friendName\'s friend request.',
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'friend_requests_channel',
            'Friend Requests',
            channelDescription: 'Notifications for friend request activities',
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
        payload: friendId,
      );
      debugPrint('Friend request rejected notification sent successfully');
    } catch (e) {
      debugPrint('Error showing friend request rejected notification: $e');
    }

    // Save to Firestore
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await addNotificationToUser(
        userId: userId,
        title: 'Friend Request Rejected',
        body: 'You rejected $friendName\'s friend request.',
        type: 'friend_request_rejected',
        isRead: false,
      );
    }
  }

  // Show a friend request received notification
  Future<void> showFriendRequestReceivedNotification({
    required String friendName,
    String? friendId,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    // Get user's phone number from Firestore
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('appUsers')
                .doc(userId)
                .get();

        final phoneNumber = userDoc.data()?['phoneNumber'] as String?;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          await sendWhatsAppMessage(
            phoneNumber,
            '👋 New Friend Request',
            '$friendName wants to connect with you on TravelBuddy! Accept their request to start planning trips together.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp notification: $e');
    }

    try {
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().microsecond,
        '👋 New Friend Request',
        '$friendName wants to connect with you on TravelBuddy! Accept their request to start planning trips together.',
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'friend_requests_channel',
            'Friend Requests',
            channelDescription: 'Notifications for friend request activities',
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
        payload: friendId,
      );
      debugPrint('Friend request received notification sent successfully');
    } catch (e) {
      debugPrint('Error showing friend request received notification: $e');
    }

    // Save to Firestore
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await addNotificationToUser(
        userId: userId,
        title: 'New Friend Request',
        body:
            '$friendName wants to connect with you on TravelBuddy! Accept their request to start planning trips together.',
        type: 'friend_request_received',
        isRead: false,
      );
    }
  }

  Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'sendPushNotification',
    );
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

  Future<bool> areNotificationsEnabled() async {
    return await Permission.notification.isGranted;
  }
}
