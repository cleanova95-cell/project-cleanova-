const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.deleteUser = onCall(
  { cors: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be logged in.");
    }

    const callerDoc = await admin.firestore()
      .collection("users")
      .doc(request.auth.uid)
      .get();

    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new HttpsError("permission-denied", "Only admins can delete users.");
    }

    const { userId } = request.data;

    if (!userId) {
      throw new HttpsError("invalid-argument", "userId is required.");
    }

    await admin.auth().deleteUser(userId);
    await admin.firestore().collection("users").doc(userId).delete();

    return { success: true };
  }
);

exports.updateUserEmail = onCall(
  { cors: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be logged in.");
    }

    const callerDoc = await admin.firestore()
      .collection("users")
      .doc(request.auth.uid)
      .get();

    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new HttpsError("permission-denied", "Only admins can update emails.");
    }

    const { userId, newEmail } = request.data;

    if (!userId || !newEmail) {
      throw new HttpsError("invalid-argument", "userId and newEmail are required.");
    }

    await admin.auth().updateUser(userId, { email: newEmail });
    await admin.firestore().collection("users").doc(userId).update({
      email: newEmail,
      updated_at: admin.firestore.Timestamp.now(),
    });

    return { success: true };
  }
);