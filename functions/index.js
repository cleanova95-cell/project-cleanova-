const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

// ─────────────────────────────────────────────────────────────────────────────
// Cloud Function: sendBookingStatusPush
// ─────────────────────────────────────────────────────────────────────────────
exports.sendBookingStatusPush = onDocumentCreated(
  "notifications/{notifId}",
  async (event) => {
    const data = event.data.data();

    const fcmToken = data?.fcmToken;
    const title    = data?.title   ?? "Booking Update";
    const message  = data?.message ?? "Your booking status has changed.";
    const status   = data?.status  ?? "";

    if (!fcmToken) {
      console.log("No FCM token found — skipping push.");
      return null;
    }

    const payload = {
      token: fcmToken,
      notification: { title, body: message },
      android: {
        notification: {
          channelId: "cleanova_booking_channel",
          priority: "high",
          color: "#43A047",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body: message },
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

// ─────────────────────────────────────────────────────────────────────────────
// Cloud Function: deleteUser
// Deletes a customer from Firebase Auth + Firestore.
// ─────────────────────────────────────────────────────────────────────────────
exports.deleteUser = onCall(async (request) => {
  // Must be a logged-in admin
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const callerSnap = await getFirestore()
    .collection("users")
    .doc(request.auth.uid)
    .get();

  if (callerSnap.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can delete users.");
  }

  const { userId } = request.data;
  if (!userId) {
    throw new HttpsError("invalid-argument", "userId is required.");
  }

  // Delete from Firebase Auth (ok if they don't have an Auth account)
  try {
    await getAuth().deleteUser(userId);
    console.log(`Auth account deleted: ${userId}`);
  } catch (err) {
    if (err.code !== "auth/user-not-found") {
      throw new HttpsError("internal", err.message);
    }
    console.warn(`No Auth account found for ${userId} — skipping Auth delete.`);
  }

  // Always delete from Firestore
  await getFirestore().collection("users").doc(userId).delete();
  console.log(`Firestore doc deleted: ${userId}`);

  return { success: true };
});

// ─────────────────────────────────────────────────────────────────────────────
// Cloud Function: updateUserEmail
// Updates a customer's login email in Firebase Auth + Firestore.
// ─────────────────────────────────────────────────────────────────────────────
exports.updateUserEmail = onCall(async (request) => {
  // Must be a logged-in admin
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const callerSnap = await getFirestore()
    .collection("users")
    .doc(request.auth.uid)
    .get();

  if (callerSnap.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can update emails.");
  }

  const { userId, newEmail } = request.data;
  if (!userId || !newEmail) {
    throw new HttpsError("invalid-argument", "userId and newEmail are required.");
  }

  // Update in Firebase Auth
  try {
    await getAuth().updateUser(userId, { email: newEmail });
    console.log(`Auth email updated for ${userId}: ${newEmail}`);
  } catch (err) {
    if (err.code === "auth/user-not-found") {
      console.warn(`No Auth account for ${userId} — skipping Auth email update.`);
    } else if (err.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "That email is already in use.");
    } else {
      throw new HttpsError("internal", err.message);
    }
  }

  // Update in Firestore
  await getFirestore().collection("users").doc(userId).update({
    email: newEmail,
    updated_at: new Date(),
  });

  return { success: true };
});