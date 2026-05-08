import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session.dart';

/// Checks the current user's admin status from Firestore `/users/{phoneKey}.isAdmin`.
/// The phone key is taken from the signed-in `User.displayName` (which the OTP
/// flow writes after a Twilio verification).
class AdminAuthService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminAuthService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? _currentKey() {
    // Prefer the in-memory User.displayName, but fall back to a direct read in
    // case this service was constructed with an injected auth instance.
    final injected = _auth.currentUser?.displayName;
    if (injected != null && injected.isNotEmpty) return injected;
    return currentUserPhoneKey();
  }

  Future<bool> isCurrentUserAdmin() async {
    final phoneKey = _currentKey();
    if (phoneKey == null || phoneKey.isEmpty) return false;
    try {
      final doc = await _firestore.collection('users').doc(phoneKey).get();
      return doc.data()?['isAdmin'] == true;
    } catch (_) {
      return false;
    }
  }

  Stream<bool> streamAdminStatus() {
    final phoneKey = _currentKey();
    if (phoneKey == null || phoneKey.isEmpty) return Stream.value(false);
    return _firestore.collection('users').doc(phoneKey).snapshots().map(
          (snap) => snap.data()?['isAdmin'] == true,
        );
  }
}

final adminAuthServiceProvider = Provider<AdminAuthService>((ref) {
  return AdminAuthService();
});

/// One-shot future provider — useful on login to decide routing.
final isCurrentUserAdminProvider = FutureProvider<bool>((ref) {
  return ref.read(adminAuthServiceProvider).isCurrentUserAdmin();
});
