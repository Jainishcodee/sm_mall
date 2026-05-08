import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_session.dart';

/// Live set of product IDs the current user has favorited. Stored as a single
/// `favoriteIds` array on the user doc keyed by phone, so toggling is O(1)
/// (one `arrayUnion` / `arrayRemove`) and reads are a single document watch.
final favoriteIdsProvider = StreamProvider<Set<String>>((ref) {
  final phoneKey = currentUserPhoneKey();
  if (phoneKey == null) return Stream.value(const <String>{});
  return FirebaseFirestore.instance
      .collection('users')
      .doc(phoneKey)
      .snapshots()
      .map((snap) {
    final raw = snap.data()?['favoriteIds'];
    if (raw is List) return raw.whereType<String>().toSet();
    return const <String>{};
  });
});

/// Toggle a product's favorite state for the signed-in user. No-op when
/// nobody is signed in (the heart button is also hidden in that case).
Future<void> toggleFavorite(String productId, {required bool isCurrentlyFavorite}) async {
  final phoneKey = currentUserPhoneKey();
  if (phoneKey == null) return;
  await FirebaseFirestore.instance.collection('users').doc(phoneKey).set({
    'favoriteIds': isCurrentlyFavorite
        ? FieldValue.arrayRemove([productId])
        : FieldValue.arrayUnion([productId]),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
