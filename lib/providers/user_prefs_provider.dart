import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class UserPrefs {
  final String deliveryAddress;
  final String deliverySlot;
  final String paymentMethod;

  const UserPrefs({
    this.deliveryAddress = '',
    this.deliverySlot = 'As soon as possible',
    this.paymentMethod = 'Cash on Delivery',
  });

  UserPrefs copyWith({
    String? deliveryAddress,
    String? deliverySlot,
    String? paymentMethod,
  }) {
    return UserPrefs(
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  factory UserPrefs.fromMap(Map<String, dynamic> data) {
    return UserPrefs(
      deliveryAddress: (data['deliveryAddress'] as String?) ?? '',
      deliverySlot: (data['deliverySlot'] as String?) ?? 'As soon as possible',
      paymentMethod: (data['paymentMethod'] as String?) ?? 'Cash on Delivery',
    );
  }

  Map<String, dynamic> toMap() => {
    'deliveryAddress': deliveryAddress,
    'deliverySlot': deliverySlot,
    'paymentMethod': paymentMethod,
  };
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UserPrefsNotifier extends AsyncNotifier<UserPrefs> {
  DocumentReference<Map<String, dynamic>>? _docRef;

  @override
  Future<UserPrefs> build() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const UserPrefs();

    _docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final snap = await _docRef!.get();
    final data = snap.data();
    if (data == null) return const UserPrefs();
    return UserPrefs.fromMap(data);
  }

  Future<void> saveAddress(String address) async {
    final current = state.valueOrNull ?? const UserPrefs();
    final updated = current.copyWith(deliveryAddress: address);
    state = AsyncData(updated);
    await _persist({'deliveryAddress': address});
  }

  Future<void> saveSlot(String slot) async {
    final current = state.valueOrNull ?? const UserPrefs();
    final updated = current.copyWith(deliverySlot: slot);
    state = AsyncData(updated);
    await _persist({'deliverySlot': slot});
  }

  Future<void> savePaymentMethod(String method) async {
    final current = state.valueOrNull ?? const UserPrefs();
    final updated = current.copyWith(paymentMethod: method);
    state = AsyncData(updated);
    await _persist({'paymentMethod': method});
  }

  Future<void> _persist(Map<String, dynamic> fields) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _docRef ??= FirebaseFirestore.instance.collection('users').doc(uid);
    await _docRef!.set({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final userPrefsProvider = AsyncNotifierProvider<UserPrefsNotifier, UserPrefs>(
  UserPrefsNotifier.new,
);
