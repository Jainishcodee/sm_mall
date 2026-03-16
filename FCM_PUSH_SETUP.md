# FCM Push Notification Setup

This project now includes:
- Flutter client token registration (`users/{uid}.fcmTokens`)
- Cloud Function trigger on `orders/{orderId}` updates
- Push notification send when `status` or `deliveryStatus` changes

## 1. Deploy Cloud Functions

```bash
cd functions
npm install
cd ..
firebase login
firebase use --add
firebase deploy --only functions
```

If you do not use `.firebaserc`, you can deploy with:

```bash
firebase deploy --only functions --project YOUR_FIREBASE_PROJECT_ID
```

## 2. Deploy Firestore Rules (if needed)

```bash
firebase deploy --only firestore:rules
```

## 3. Android notes

- `POST_NOTIFICATIONS` permission is already added in `AndroidManifest.xml`.
- On Android 13+, user must allow notifications once prompted.

## 4. iOS notes (required for iOS push)

- Enable Push Notifications capability in Runner target.
- Enable Background Modes -> Remote notifications.
- Upload APNs key/certificate in Firebase Console.

## 5. How it works

1. User logs in.
2. App requests notification permission and stores FCM token in `users/{uid}`.
3. Admin updates `status` or `deliveryStatus` on an order.
4. Cloud Function `notifyOrderStatusChanged` sends push to that user's tokens.

## 6. Test checklist

1. Login as user on physical device and place order.
2. Verify token exists in `users/{uid}` (`fcmToken` and `fcmTokens`).
3. Login as admin and change order status to `Accepted` / `On the way` / `Delivered`.
4. User device receives push for each change.
