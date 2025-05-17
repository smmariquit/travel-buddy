// Enhanced Firebase Cloud Function with debugging
const functions = require("firebase-functions");
const admin = require("firebase-admin");
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