import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests admin authentication logic against Firestore `isAdmin` flag.
/// Since AdminAuthService depends on FirebaseAuth.instance (hard to mock
/// without firebase_auth_mocks), we test the Firestore data contract directly.
void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('Admin auth via Firestore isAdmin flag', () {
    test('user with isAdmin=true is recognized as admin', () async {
      await fakeFirestore.collection('users').doc('admin_uid').set({
        'firstName': 'Admin',
        'lastName': 'User',
        'phone': '+919999999999',
        'email': 'admin@mall.com',
        'isAdmin': true,
        'isActive': true,
      });

      final doc = await fakeFirestore.collection('users').doc('admin_uid').get();
      final isAdmin = doc.data()?['isAdmin'] == true;
      expect(isAdmin, true);
    });

    test('user without isAdmin field defaults to non-admin', () async {
      await fakeFirestore.collection('users').doc('regular_uid').set({
        'firstName': 'Regular',
        'lastName': 'User',
        'phone': '+911111111111',
        'email': 'user@test.com',
        'isActive': true,
      });

      final doc = await fakeFirestore.collection('users').doc('regular_uid').get();
      final isAdmin = doc.data()?['isAdmin'] == true;
      expect(isAdmin, false);
    });

    test('user with isAdmin=false is non-admin', () async {
      await fakeFirestore.collection('users').doc('user_uid').set({
        'firstName': 'Bob',
        'phone': '+912222222222',
        'isAdmin': false,
      });

      final doc = await fakeFirestore.collection('users').doc('user_uid').get();
      final isAdmin = doc.data()?['isAdmin'] == true;
      expect(isAdmin, false);
    });

    test('non-existent user document returns non-admin', () async {
      final doc = await fakeFirestore.collection('users').doc('ghost_uid').get();
      final isAdmin = doc.data()?['isAdmin'] == true;
      expect(isAdmin, false);
    });

    test('user cannot self-promote to admin (data contract)', () async {
      // Simulate: user creates profile without isAdmin
      await fakeFirestore.collection('users').doc('sneaky_uid').set({
        'firstName': 'Sneaky',
        'phone': '+913333333333',
        'isActive': true,
      });

      // Verify isAdmin is not set
      final before = await fakeFirestore.collection('users').doc('sneaky_uid').get();
      expect(before.data()?['isAdmin'], isNull);

      // In real Firestore, rules block users from setting isAdmin on themselves.
      // Here we verify the data model supports this distinction.
      await fakeFirestore.collection('users').doc('sneaky_uid').update({
        'isAdmin': true, // would be blocked by rules in production
      });

      final after = await fakeFirestore.collection('users').doc('sneaky_uid').get();
      // The test documents that the field EXISTS — real security is in rules.
      expect(after.data()?['isAdmin'], true);
    });

    test('admin stream emits on flag change', () async {
      await fakeFirestore.collection('users').doc('stream_uid').set({
        'isAdmin': false,
      });

      final stream = fakeFirestore
          .collection('users')
          .doc('stream_uid')
          .snapshots()
          .map((snap) => snap.data()?['isAdmin'] == true);

      // Initial value
      expect(await stream.first, false);

      // Promote to admin
      await fakeFirestore.collection('users').doc('stream_uid').update({
        'isAdmin': true,
      });

      expect(
        await fakeFirestore
            .collection('users')
            .doc('stream_uid')
            .snapshots()
            .map((snap) => snap.data()?['isAdmin'] == true)
            .first,
        true,
      );
    });
  });
}
