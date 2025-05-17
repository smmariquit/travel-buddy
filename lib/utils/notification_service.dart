import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

final FirebaseFunctions _functions = FirebaseFunctions.instance;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize local notifications with tap handling
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          print('Notification tapped with payload: $payload');
          // TODO: Navigate to specific screen based on payload if needed
        }
      },
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen for token refresh and save new token
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);

    // Get current FCM token and save it
    String? token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Check for upcoming trips and notify
    _checkUpcomingTrips();
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'New Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('appUsers').doc(userId).update({
        'fcmToken': token,
      });
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'travel_app_channel',
      'Travel App Notifications',
      channelDescription: 'Notifications from Travel App',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> _checkUpcomingTrips() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final tripsSnapshot = await FirebaseFirestore.instance
        .collection('trips')
        .where('sharedWith', arrayContains: userId)
        .get();

    final now = DateTime.now();

    for (var doc in tripsSnapshot.docs) {
      final travel = Travel.fromJson(doc.data(), doc.id);

      if (travel.startDate != null) {
        final daysUntilTrip = travel.startDate!.difference(now).inDays;

        if (daysUntilTrip == 5) {
          await _showLocalNotification(
            title: 'Upcoming Trip: ${travel.name}',
            body: 'Your trip to ${travel.location} starts in 5 days! Time to prepare!',
            payload: 'trip_${travel.id}',
          );
        }
      }
    }
  }

  Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    try {
      // Format exactly as the cloud function expects
      final data = {
        'to': fcmToken, // Use 'to' for the FCM token
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'fcmToken': fcmToken, // Optional: include the token in data if needed
        },
      };
      
      // Debug print to verify data being sent
      print('Sending notification with data: $data');
      
      final result = await _functions.httpsCallable('sendPushNotification').call(data);
      print('Notification sent successfully: ${result.data}');
    } catch (e) {
      print('Error sending notification: $e');
      // Add more detailed error reporting
      if (e is FirebaseFunctionsException) {
        print('Function error code: ${e.code}');
        print('Function error details: ${e.details}');
      }
    }
  }

  Future<void> sendFriendRequestNotification(String receiverUserId, String senderName) async {
    final userDoc = await FirebaseFirestore.instance.collection('appUsers').doc(receiverUserId).get();

    if (!userDoc.exists) return;

    final AppUser user = AppUser.fromJson(userDoc.data()!);
    final String? fcmToken = user.fcmToken;

    if (fcmToken == null || fcmToken.isEmpty) return;

    print('Would send notification to token: $fcmToken');
    print('Notification content: New friend request from $senderName');

    await _showLocalNotification(
      title: 'New Friend Request',
      body: 'You received a friend request from $senderName',
      payload: 'friend_request',
    );
  }

  void scheduleUpcomingTripChecks() {
    _checkUpcomingTrips();
  }
}

// Future<void> sendPushNotification({
//   required String fcmToken,
//   required String title,
//   required String body,
// }) async {
//   try {
//     // Format exactly as the cloud function expects
//     final data = {
//       'fcmToken': fcmToken,
//       'title': title,
//       'body': body,
//     };
    
//     // Debug print to verify data being sent
//     print('Sending notification with data: $data');
    
//     final result = await _functions.httpsCallable('sendPushNotification').call(data);
//     print('Notification sent successfully: ${result.data}');
//   } catch (e) {
//     print('Error sending notification: $e');
//     // Add more detailed error reporting
//     if (e is FirebaseFunctionsException) {
//       print('Function error code: ${e.code}');
//       print('Function error details: ${e.details}');
//     }
//   }
// }

Future<void> sendPushNotification({
  required String fcmToken,
  required String title,
  required String body,
}) async {
  try {
    // Format exactly as the cloud function expects
    final data = {
      "to": fcmToken, // Use 'to' for the FCM token
      "notification": {
        "title": title,
        "body": body,
      },
      "data": {
        "fcmToken": fcmToken, // Optional: include the token in data if needed
      },
    };
    
    // Debug print to verify data being sent
    print('Sending notification with data: $data');
    
    final result = await _functions.httpsCallable('sendPushNotification').call(data);
    print('Notification sent successfully: ${result.data}');
  } catch (e) {
    print('Error sending notification: $e');
    // Add more detailed error reporting
    if (e is FirebaseFunctionsException) {
      print('Function error code: ${e.code}');
      print('Function error details: ${e.details}');
    }
  }
}