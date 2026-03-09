import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/delivery_zone.dart';

const _deliveryZoneCollection = 'app_settings';
const _deliveryZoneDoc = 'delivery_zone';

final deliveryZoneDocProvider =
    Provider<DocumentReference<Map<String, dynamic>>>(
      (ref) => FirebaseFirestore.instance
          .collection(_deliveryZoneCollection)
          .doc(_deliveryZoneDoc),
    );

final deliveryZoneProvider = StreamProvider<DeliveryZone>((ref) {
  final docRef = ref.watch(deliveryZoneDocProvider);
  return docRef.snapshots().map((snapshot) {
    final data = snapshot.data();
    if (data == null) {
      return DeliveryZone.fallback();
    }
    return DeliveryZone.fromMap(data);
  });
});

class DeliveryZoneAdminNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> saveZone(DeliveryZone zone) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final docRef = ref.read(deliveryZoneDocProvider);
      await docRef.set({
        ...zone.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}

final deliveryZoneAdminProvider =
    AsyncNotifierProvider<DeliveryZoneAdminNotifier, void>(
      DeliveryZoneAdminNotifier.new,
    );
