const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyOrderStatusChanged = functions.firestore
    .document("orders/{orderId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data() || {};
      const after = change.after.data() || {};

      const statusChanged = before.status !== after.status;
      const deliveryChanged = before.deliveryStatus !== after.deliveryStatus;

      if (!statusChanged && !deliveryChanged) {
        return null;
      }

      const userId = after.userId;
      if (!userId) {
        console.log("No userId on order", context.params.orderId);
        return null;
      }

      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const userData = userDoc.data() || {};

      let tokens = [];
      if (Array.isArray(userData.fcmTokens)) {
        tokens = userData.fcmTokens.filter((t) => typeof t === "string" && t.length > 0);
      }
      if (tokens.length === 0 && typeof userData.fcmToken === "string" && userData.fcmToken.length > 0) {
        tokens = [userData.fcmToken];
      }

      if (tokens.length === 0) {
        console.log("No FCM tokens for user", userId);
        return null;
      }

      const shortOrderId = String(context.params.orderId).substring(0, 8).toUpperCase();
      const status = String(after.status || "Pending");
      const deliveryStatus = String(after.deliveryStatus || "Pending");

      const message = {
        tokens,
        notification: {
          title: `Order #${shortOrderId} updated`,
          body: `Status: ${status} | Delivery: ${deliveryStatus}`,
        },
        data: {
          type: "order_update",
          orderId: String(context.params.orderId),
          status,
          deliveryStatus,
        },
        android: {
          priority: "high",
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      // Cleanup invalid tokens to keep collection healthy.
      const invalidTokens = [];
      response.responses.forEach((r, i) => {
        if (!r.success && r.error) {
          const code = r.error.code || "";
          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-argument"
          ) {
            invalidTokens.push(tokens[i]);
          }
        }
      });

      if (invalidTokens.length > 0) {
        await admin.firestore().collection("users").doc(userId).set({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
        }, { merge: true });
      }

      return null;
    });
