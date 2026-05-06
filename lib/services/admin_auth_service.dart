import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Checks the current user's admin status from Firestore `/users/{uid}.isAdmin`.
class AdminAuthService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminAuthService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Returns `true` when the signed-in user has `isAdmin: true` in Firestore.
  Future<bool> isCurrentUserAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['isAdmin'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Stream that emits whenever the admin flag changes.
  Stream<bool> streamAdminStatus() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(false);
    return _firestore.collection('users').doc(uid).snapshots().map(
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
