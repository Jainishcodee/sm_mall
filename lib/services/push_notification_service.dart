import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../screens/order_tracking_screen.dart';
import 'auth_session.dart';

/// Background handler required by Firebase Messaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: Android/iOS shows notification payload automatically in background.
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  String? _pendingOrderId;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        return;
      }
      try {
        await _requestPermissions();
        final phoneKey = currentUserPhoneKey();
        if (phoneKey != null) {
          await _syncTokenForUser(phoneKey);
        }
      } catch (e) {
        debugPrint('[push] auth-state token sync failed: $e');
      }
    });

    _messaging.onTokenRefresh.listen((token) async {
      try {
        final phoneKey = currentUserPhoneKey();
        if (phoneKey == null) {
          return;
        }
        await _saveToken(phoneKey, token);
      } catch (e) {
        debugPrint('[push] token-refresh save failed: $e');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // Don't block init on platform channel calls or Firestore writes —
    // they can hang on cold start (e.g. stale auth token, slow GMS).
    // ignore: discarded_futures
    _handleInitialMessageSafe();
    // ignore: discarded_futures
    _bootstrapTokenForCurrentUser();
  }

  Future<void> _handleInitialMessageSafe() async {
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpened(initialMessage);
      }
    } catch (e) {
      debugPrint('[push] getInitialMessage failed: $e');
    }
  }

  Future<void> _bootstrapTokenForCurrentUser() async {
    try {
      final phoneKey = currentUserPhoneKey();
      if (phoneKey == null) return;
      await _requestPermissions();
      await _syncTokenForUser(phoneKey);
    } catch (e) {
      debugPrint('[push] bootstrap token sync failed: $e');
    }
  }

  void onAppReady() {
    if (_pendingOrderId == null) {
      return;
    }
    _openOrderTracking(_pendingOrderId!);
    _pendingOrderId = null;
  }

  void _handleMessageOpened(RemoteMessage message) {
    final orderId = message.data['orderId']?.toString();
    if (orderId == null || orderId.isEmpty) {
      return;
    }

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      _pendingOrderId = orderId;
      return;
    }
    _openOrderTracking(orderId);
  }

  void _openOrderTracking(String orderId) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      _pendingOrderId = orderId;
      return;
    }

    navigator.push(
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)),
    );
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      await _messaging.requestPermission();
      return;
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _syncTokenForUser(String phoneKey) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    await _saveToken(phoneKey, token);
  }

  Future<void> _saveToken(String phoneKey, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(phoneKey).set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Most common cause: stale auth token on cold start, or rules denying
      // a write before getIdToken(true) refreshes the `name` claim.
      // The token-refresh listener will retry on next FCM token rotation,
      // and the OTP flow refreshes the ID token explicitly on login.
      debugPrint('[push] Firestore token write denied: $e');
    }
  }
}
