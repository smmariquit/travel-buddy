// Enhanced Firebase Cloud Function with debugging
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { NotificationService } = require('./notification_service');

admin.initializeApp();
const notificationService = new NotificationService();

exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  // Add detailed logging to troubleshoot the structure of incoming data
  console.log("Received data:", JSON.stringify(data));

  // Validate the data structure more explicitly
  if (!data) {
    console.error("No data provided");
    throw new functions.https.HttpsError(
      "invalid-argument",
      "No data provided to the function"
    );
  }

  // Check token exists
  if (!data.token) {
    console.error("Missing token in request");
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing token field in request data"
    );
  }

  // Check notification exists and has required fields
  if (!data.notification || !data.notification.title || !data.notification.body) {
    console.error("Missing or incomplete notification object", data.notification);
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing or incomplete notification object"
    );
  }

  try {
    // Build message payload according to FCM requirements
    const message = {
      token: data.token,
      notification: {
        title: data.notification.title,
        body: data.notification.body
      },
      data: data.data || {},
    };

    console.log("Sending message:", JSON.stringify(message));

    // Send using the correct FCM method
    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error("Error sending message:", error);
    throw new functions.https.HttpsError("unknown", error.message, error);
  }
});

// Scheduled function to check for upcoming trips and notify users every 5 minutes
exports.checkTripsAndNotify = onSchedule(
  { schedule: 'every 1 minutes' },
  async (event) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const nowDate = now.toDate(); // Convert to JS Date
    const nowMs = nowDate.getTime();

    // Query all trips
    const tripsSnapshot = await db.collection('travel').get();

    for (const tripDoc of tripsSnapshot.docs) {
      const trip = tripDoc.data();
      const tripId = tripDoc.id;
      const startDate = trip.startDate;
      if (!startDate) continue;
      const startTimestamp = startDate._seconds ? new Date(startDate._seconds * 1000) : startDate.toDate();

      // Get all users to notify: creator and sharedWith
      let userIds = [];
      if (trip.uid) userIds.push(trip.uid);
      if (Array.isArray(trip.sharedWith)) userIds = userIds.concat(trip.sharedWith);
      userIds = [...new Set(userIds)]; // Remove duplicates

      for (const userId of userIds) {
        // Get user document
        const userDoc = await db.collection('appUsers').doc(userId).get();
        if (!userDoc.exists) continue;
        const user = userDoc.data();
        const fcmToken = user.fcmToken;
        if (!fcmToken) continue;

        // Get notification interval from the travel plan (default to 5 days)
        const notificationDays = trip.notificationDays || 5;

        // Calculate the window
        const msInDay = 24 * 60 * 60 * 1000;
        const startMs = startTimestamp.getTime();
        const daysUntilTrip = (startMs - nowMs) / msInDay;

        // Only send if we're in the 24-hour window for notificationDays
        if (
          daysUntilTrip <= notificationDays &&
          daysUntilTrip > (notificationDays - 1)
        ) {
          // Check notified count in the travel document
          const notifiedMap = trip.notified || {};
          const notifiedCount = notifiedMap[userId] ?? 0;
          if (notifiedCount >= 1) continue; // Already notified at least once

          // Send push notification
          const notification = {
            title: 'Upcoming Trip Reminder',
            body: `Your trip "${trip.name || 'Unnamed Trip'}" starts in ${Math.round(daysUntilTrip)} day(s)!`,
          };
          try {
            await admin.messaging().send({
              token: fcmToken,
              notification,
              data: { tripId },
            });

            // Add in-app notification to Firestore
            await db.collection('appUsers')
              .doc(userId)
              .collection('notifications')
              .add({
                title: notification.title,
                body: notification.body,
                tripId: tripId,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                read: false,
                type: 'trip_reminder',
              });

            // Update notified count in the travel document
            console.log(`Updating notified count for user ${userId} in trip ${tripId}...`);
            notifiedMap[userId] = notifiedCount + 1;
            await db.collection('travel').doc(tripId).update({
              [`notified.${userId}`]: notifiedMap[userId]
            });
            console.log(`Updated notified count for user ${userId} in trip ${tripId}.`);
          } catch (e) {
            console.error(`Failed to send notification to user ${userId} for trip ${tripId}:`, e);
          }
        }
      }
    }
  }
);