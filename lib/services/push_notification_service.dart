import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../screens/order_tracking_screen.dart';

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
      await _requestPermissions();
      await _syncTokenForUser(user.uid);
    });

    _messaging.onTokenRefresh.listen((token) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return;
      }
      await _saveToken(uid, token);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpened(initialMessage);
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _requestPermissions();
      await _syncTokenForUser(uid);
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

  Future<void> _syncTokenForUser(String uid) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    await _saveToken(uid, token);
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
