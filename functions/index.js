// Enhanced Firebase Cloud Function with debugging
const functions = require("firebase-functions");
const admin = require("firebase-admin");

const {logger} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
admin.initializeApp();

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
exports.checkTripsAndNotify = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  // Query all trips
  const tripsSnapshot = await db.collection('travel').get();

  for (const tripDoc of tripsSnapshot.docs) {
    const trip = tripDoc.data();
    const tripId = tripDoc.id;
    const startDate = trip.startDate;
    if (!startDate) continue;
    const startTimestamp = startDate._seconds ? new Date(startDate._seconds * 1000) : startDate.toDate();
    const daysUntilTrip = Math.ceil((startTimestamp - new Date()) / (1000 * 60 * 60 * 24));

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

      // Get notification interval from user (default to 5 days)
      const notificationDays = user.notificationDays || 5;
      // Check if notification should be sent
      if (daysUntilTrip <= notificationDays && daysUntilTrip >= 0) {
        // Check if notification already sent for this trip and user
        const notifRef = db.collection('appUsers').doc(userId).collection('notifications').doc(tripId);
        const notifDoc = await notifRef.get();
        if (notifDoc.exists && notifDoc.data().notified) continue;

        // Send push notification
        const notification = {
          title: 'Upcoming Trip Reminder',
          body: `Your trip "${trip.name || 'Unnamed Trip'}" starts in ${daysUntilTrip} day(s)!`,
        };
        try {
          await admin.messaging().send({
            token: fcmToken,
            notification,
            data: { tripId },
          });
          // Mark as notified
          await notifRef.set({
            title: notification.title,
            body: notification.body,
            type: 'trip_reminder',
            read: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            notified: true,
            tripId,
          });
          console.log(`Notification sent to user ${userId} for trip ${tripId}`);
        } catch (e) {
          console.error(`Failed to send notification to user ${userId} for trip ${tripId}:`, e);
        }
      }
    }
  }
});