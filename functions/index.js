// /**
//  * Import function triggers from their respective submodules:
//  *
//  * const {onCall} = require("firebase-functions/v2/https");
//  * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
//  *
//  * See a full list of supported triggers at https://firebase.google.com/docs/functions
//  */

// // const {onRequest} = require("firebase-functions/v2/https");
// // const logger = require("firebase-functions/logger");

// // Create and deploy your first functions
// // https://firebase.google.com/docs/functions/get-started

// // exports.helloWorld = onRequest((request, response) => {
// //   logger.info("Hello logs!", {structuredData: true});
// //   response.send("Hello from Firebase!");
// // });

// const functions = require("firebase-functions");
// const admin = require("firebase-admin");
// admin.initializeApp();

// // exports.sendNotification = functions.https.onCall((data, context) => {
// //   const token = data.fcmToken;
// //   const title = data.title;
// //   const body = data.body;

// //   if (!token || !title || !body) {
// //     throw new functions.https.HttpsError(
// //     'invalid-argument', 'Missing notification data');
// //   }

// //   const message = {
// //     token: token,
// //     notification: {
// //       title: title,
// //       body: body
// //     }
// //   };

// //   return admin.messaging().send(message);
// // });


// // exports.sendPushNotification = functions
// // .https.onCall(async (data, context) => {
// //   const {fcmToken, title, body} = data;

// //   if (!fcmToken || !title || !body) {
// //     throw new functions.https.HttpsError(
// //         "invalid-argument",
// //         "Missing notification data");
// //   }

// //   const message = {
// //     token: fcmToken,
// //     notification: {
// //       title,
// //       body,
// //     },
// //   };

// //   try {
// //     const response = await admin.messaging().send(message);
// //     return {success: true, response};
// //   } catch (error) {
// //     throw new functions.https.HttpsError("unknown", error.message, error);
// //   }
// // });

// exports.sendNotification = functions.https.onCall(async (data, context) => {
//   console.log("Received data:", data);

//   const {fcmToken, title, body} = data;

//   if (!fcmToken || !title || !body) {
//     console.error("Missing fields:", {fcmToken, title, body});
//     throw new functions.https.HttpsError(
//         "invalid-argument", "Missing notification data");
//   }

//   const message = {
//     token: fcmToken,
//     notification: {
//       title,
//       body,
//     },
//   };

//   try {
//     const response = await admin.messaging().send(message);
//     return {success: true, response};
//   } catch (err) {
//     console.error("Failed to send message:", err);
//     throw new functions.https.HttpsError(
//         "internal", "Notification sending failed");
//   }
// });

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  const {to, notification, data: additionalData} = data;

  // Check if the required fields are present
  if (!to || !notification) {
    throw new functions.https.HttpsError('invalid-argument', 'The function must be called with "to" and "notification" fields.');
  }

  const payload = {
    notification: notification,
    data: additionalData || {}, // Use an empty object if additionalData is not provided
  };

  try {
    const response = await admin.messaging().sendToDevice(to, payload);
    return { success: true, response: response };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});
