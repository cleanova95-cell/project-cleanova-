const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// ─────────────────────────────────────────────────────────────────────────────
// Cloud Function: sendBookingStatusPush
//
// Triggers whenever a new document is created in the "notifications" collection.
// It reads the fcmToken field and sends a real push notification to the
// customer's phone — this is what creates the popup banner on their screen.
// ─────────────────────────────────────────────────────────────────────────────
exports.sendBookingStatusPush = onDocumentCreated(
  "notifications/{notifId}",
  async (event) => {
    const data = event.data.data();

    const fcmToken = data?.fcmToken;
    const title = data?.title ?? "Booking Update";
    const message = data?.message ?? "Your booking status has changed.";
    const status = data?.status ?? "";

    // No token = can't send push (user hasn't logged in on this device yet)
    if (!fcmToken) {
      console.log("No FCM token found — skipping push.");
      return null;
    }

    const payload = {
      token: fcmToken,
      notification: {
        title: title,
        body: message,
      },
      android: {
        notification: {
          channelId: "cleanova_booking_channel",  // must match Flutter channel id
          priority: "high",
          color: "#43A047",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title: title, body: message },
            sound: "default",
            badge: 1,
          },
        },
      },
      data: {
        bookingStatus: status,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      const response = await getMessaging().send(payload);
      console.log("Push sent successfully:", response);
    } catch (error) {
      console.error("Error sending push:", error);
    }

    return null;
  }
);
