import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:travel_app/models/travel_plan_model.dart'; // Add import for Travel model
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
      final notificationService = NotificationService();

      // Initialize notification service
      await notificationService.init();

      final TwilioFlutter twilioFlutter = TwilioFlutter(
        accountSid: 'ACa6cfdca8cf8927d69fda634125c3d138',
        authToken: 'b2ad8ed6fc74654884123560e2fb3bfb',
        twilioNumber: 'whatsapp:+14155238886',
      );

      // Check if we have permission
      final hasPermission = await notificationService.areNotificationsEnabled();
      if (!hasPermission) {
        debugPrint('Notification permissions not granted');
        return;
      }

      final authProvider = Provider.of<AppUserProvider>(context, listen: false);
      final userId = authProvider.uid;

      if (userId == null) {
        debugPrint('No user logged in, skipping notification check');
        return;
      }

      // Save FCM token to user's Firestore document
      if (notificationService.fcmToken != null) {
        await notificationService.saveTokenToFirestore(userId);
      }

      final travelProvider = Provider.of<TravelTrackerProvider>(
        context,
        listen: false,
      );
      final trips = await travelProvider.getTravelPlans();

      final now = DateTime.now();
      bool hasNotifiedUser = false;

      for (final trip in trips) {
        // Skip if notification was dismissed or trip has no ID
        if (trip.id == null) {
          continue;
        }

        try {
          // Since startDate is DateTime?, we need to check if it's null
          if (trip.startDate == null) {
            continue;
          }

          // Skip trips that have already started
          if (trip.startDate!.isBefore(now)) {
            continue;
          }

          // Calculate days until trip
          final daysUntilTrip = trip.startDate!.difference(now).inDays;

          // Use reminderDays if available, otherwise default to 3
          final reminderDays = 3; // Default value

          // Check if we should send a notification for this trip
          if (daysUntilTrip <= reminderDays) {
            // Don't show too many notifications at once
            if (!hasNotifiedUser) {
              // Show notification for this trip
              final message =
                  daysUntilTrip == 0
                      ? 'Your trip starts today!'
                      : daysUntilTrip == 1
                      ? 'Your trip starts tomorrow!'
                      : 'Your trip starts in $daysUntilTrip days';

              // Send local notification
              await notificationService.showTripReminderNotification(
                title: 'Upcoming Trip: ${trip.name ?? 'Your Trip'}',
                body: message,
                payload: trip.id,
              );

              // Send Twilio WhatsApp message
              try {
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

              // Update the trip with notification ID
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
            }
          }
        } catch (e) {
          debugPrint('Error processing trip date for notifications: $e');
        }
      }
    } catch (e) {
      debugPrint('Error checking for notifications: $e');
    }
  }
}
