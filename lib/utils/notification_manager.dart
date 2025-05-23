import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Add import for Travel model
import 'package:travel_app/utils/notification_service.dart'; // Updated path based on actual service
import 'package:travel_app/providers/travel_plans_provider.dart'; // Updated provider name
import 'package:travel_app/providers/user_provider.dart';
import 'package:twilio_flutter/twilio_flutter.dart'; // Updated provider name

class NotificationManager {
  // Check for upcoming trips and schedule notifications if needed
  static Future<void> checkForUpcomingNotifications(
    BuildContext context,
  ) async {
    try {
      debugPrint('=== NOTIFICATION CHECK START ===');
      final notificationService = NotificationService();

      // Initialize notification service
      debugPrint('Initializing notification service...');
      await notificationService.init();
      debugPrint('Notification service initialized');

      final TwilioFlutter twilioFlutter = TwilioFlutter(
        accountSid: 'ACa6cfdca8cf8927d69fda634125c3d138',
        authToken: 'b2ad8ed6fc74654884123560e2fb3bfb',
        twilioNumber: 'whatsapp:+14155238886',
      );

      // Check if we have permission
      debugPrint('Checking notification permissions...');
      final hasPermission = await notificationService.areNotificationsEnabled();
      if (!hasPermission) {
        debugPrint('Notification permissions not granted');
        return;
      }
      debugPrint('Notification permissions granted');

      final authProvider = Provider.of<AppUserProvider>(context, listen: false);
      final userId = authProvider.uid;

      if (userId == null) {
        debugPrint('No user logged in, skipping notification check');
        return;
      }
      debugPrint('User ID found: $userId');

      // Save FCM token to user's Firestore document
      if (notificationService.fcmToken != null) {
        debugPrint('Saving FCM token to Firestore...');
        await notificationService.saveTokenToFirestore(userId);
        debugPrint('FCM token saved');
      }

      debugPrint('Getting travel plans...');
      final travelProvider = Provider.of<TravelTrackerProvider>(
        context,
        listen: false,
      );
      final trips = await travelProvider.getTravelPlans();
      debugPrint('Found ${trips.length} trips');

      final now = DateTime.now();
      bool hasNotifiedUser = false;

      for (final trip in trips) {
        debugPrint('Processing trip: ${trip.name}');
        // Skip if notification was dismissed or trip has no ID
        try {
          // Since startDate is DateTime?, we need to check if it's null
          if (trip.startDate == null) {
            debugPrint('Trip has no start date, skipping');
            continue;
          }

          // Skip trips that have already started
          if (trip.startDate!.isBefore(now)) {
            debugPrint('Trip has already started, skipping');
            continue;
          }

          // Calculate days until trip
          final daysUntilTrip = trip.startDate!.difference(now).inDays;
          debugPrint('Days until trip: $daysUntilTrip');

          // Use reminderDays if available, otherwise default to 3
          final reminderDays = 3; // Default value

          // Check if we should send a notification for this trip
          if (daysUntilTrip <= reminderDays) {
            debugPrint('Trip is within reminder period');
            // Don't show too many notifications at once
            if (!hasNotifiedUser) {
              debugPrint(
                'User has not been notified yet, proceeding with notifications',
              );
              // Show notification for this trip
              final message =
                  daysUntilTrip == 0
                      ? 'Your trip starts today!'
                      : daysUntilTrip == 1
                      ? 'Your trip starts tomorrow!'
                      : 'Your trip starts in $daysUntilTrip days';

              debugPrint('Preparing to send notifications...');
              // Send local notification
              await notificationService.showTripReminderNotification(
                title: 'Upcoming Trip: ${trip.name ?? 'Your Trip'}',
                body: message,
                payload: trip.id,
              );
              debugPrint('Local notification sent');

              debugPrint('=== SMS NOTIFICATION PROCESS START ===');
              // Send SMS notification
              try {
                debugPrint('Fetching user document for userId: $userId');
                final userDoc =
                    await FirebaseFirestore.instance
                        .collection('appUsers')
                        .doc(userId)
                        .get();
                debugPrint('User document fetched: ${userDoc.exists}');

                final phoneNumber = userDoc.data()?['phoneNumber'] as String?;
                debugPrint('Phone number from document: $phoneNumber');

                if (phoneNumber != null && phoneNumber.isNotEmpty) {
                  debugPrint('Attempting to send SMS to: $phoneNumber');
                  debugPrint('Message content: $message');

                  await notificationService.sendSMS(
                    phoneNumber: phoneNumber,
                    message: "Hey, Buddy! ✈️🌍\nr $message",
                  );
                  debugPrint('SMS send call completed');
                } else {
                  debugPrint('No phone number found for user: $userId');
                }
              } catch (e, stackTrace) {
                debugPrint('=== SMS SENDING FAILED ===');
                debugPrint('Error: $e');
                debugPrint('Stack trace: $stackTrace');
              }
              debugPrint('=== SMS NOTIFICATION PROCESS END ===');

              // Send Twilio WhatsApp message
              try {
                debugPrint('Sending WhatsApp message...');
                TwilioResponse response = await twilioFlutter.sendWhatsApp(
                  toNumber:
                      'whatsapp:+639606878535', // Replace with user's WhatsApp number
                  messageBody:
                      '🚨 Trip Reminder 🚨\n\n'
                      'Trip: ${trip.name ?? 'Your Trip'}\n'
                      'Destination: ${trip.location ?? 'Not specified'}\n'
                      '$message\n\n'
                      'Start Date: ${trip.startDate?.toString().split(' ')[0] ?? 'Not specified'}\n'
                      'End Date: ${trip.endDate?.toString().split(' ')[0] ?? 'Not specified'}',
                );
                debugPrint(
                  'Twilio message sent successfully: ${response.toString()}',
                );
              } catch (e) {
                debugPrint('Error sending Twilio message: $e');
              }

              hasNotifiedUser = true;
              debugPrint(
                'User has been notified, setting hasNotifiedUser to true',
              );

              // Update the trip with notification ID
              debugPrint('Updating trip in Firestore...');
              final updatedTrip = trip.copyWith(
                id: trip.id,
                uid: trip.uid,
                name: trip.name,
                startDate: trip.startDate,
                endDate: trip.endDate,
                location: trip.location,
                flightDetails: trip.flightDetails,
                accommodation: trip.accommodation,
                notes: trip.notes,
                checklist: trip.checklist,
                activities: trip.activities,
                createdOn: trip.createdOn,
              );
              await travelProvider.updateTravelPlan(updatedTrip);
              debugPrint('Trip updated in Firestore');
            } else {
              debugPrint(
                'User has already been notified, skipping notifications',
              );
            }
          } else {
            debugPrint('Trip is not within reminder period, skipping');
          }
        } catch (e) {
          debugPrint('Error processing trip date for notifications: $e');
        }
      }
      debugPrint('=== NOTIFICATION CHECK END ===');
    } catch (e) {
      debugPrint('Error checking for notifications: $e');
    }
  }
}
