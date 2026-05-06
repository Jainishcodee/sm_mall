import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ─────────────────────────────────────────────
  // PRODUCT OPERATIONS
  // ─────────────────────────────────────────────

  group('Product upload / CRUD', () {
    test('add product writes correct data to Firestore', () async {
      final ref = await fakeFirestore.collection('products').add({
        'name': 'Organic Milk',
        'category': 'Dairy',
        'price': 65.0,
        'unit': '1L',
        'stockNote': 'Fresh',
        'isActive': true,
        'description': 'Farm-fresh organic milk',
        'imageUrl': 'https://cdn.example.com/milk.jpg',
        'storeId': 'mall',
      });

      final doc = await fakeFirestore.collection('products').doc(ref.id).get();
      final data = doc.data()!;

      expect(doc.exists, true);
      expect(data['name'], 'Organic Milk');
      expect(data['category'], 'Dairy');
      expect(data['price'], 65.0);
      expect(data['unit'], '1L');
      expect(data['storeId'], 'mall');
      expect(data['isActive'], true);
      expect(data['imageUrl'], 'https://cdn.example.com/milk.jpg');
    });

    test('update product modifies existing document', () async {
      final ref = await fakeFirestore.collection('products').add({
        'name': 'Bread',
        'category': 'Bakery',
        'price': 40.0,
        'unit': '1 pack',
        'isActive': true,
        'storeId': 'mall',
      });

      await fakeFirestore.collection('products').doc(ref.id).update({
        'price': 45.0,
        'stockNote': 'Price increased',
      });

      final doc = await fakeFirestore.collection('products').doc(ref.id).get();
      expect(doc.data()!['price'], 45.0);
      expect(doc.data()!['stockNote'], 'Price increased');
      expect(doc.data()!['name'], 'Bread'); // unchanged
    });

    test('delete product removes document', () async {
      final ref = await fakeFirestore.collection('products').add({
        'name': 'Expired Item',
        'category': 'Other',
        'price': 10.0,
        'unit': '1 pc',
        'isActive': false,
        'storeId': 'mall',
      });

      await fakeFirestore.collection('products').doc(ref.id).delete();

      final doc = await fakeFirestore.collection('products').doc(ref.id).get();
      expect(doc.exists, false);
    });

    test('stream active products filters inactive items', () async {
      await fakeFirestore.collection('products').add({
        'name': 'Active Product',
        'isActive': true,
        'price': 100.0,
        'storeId': 'mall',
      });
      await fakeFirestore.collection('products').add({
        'name': 'Inactive Product',
        'isActive': false,
        'price': 50.0,
        'storeId': 'mall',
      });

      final snapshot = await fakeFirestore.collection('products').get();
      final activeProducts = snapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .toList();

      expect(activeProducts.length, 1);
      expect(activeProducts.first.data()['name'], 'Active Product');
    });

    test('stream store products filters by storeId', () async {
      await fakeFirestore.collection('products').add({
        'name': 'Mall Product',
        'isActive': true,
        'storeId': 'mall',
        'price': 100.0,
      });
      await fakeFirestore.collection('products').add({
        'name': 'Store2 Product',
        'isActive': true,
        'storeId': 'store2',
        'price': 200.0,
      });

      final snapshot = await fakeFirestore.collection('products').get();
      final mallProducts = snapshot.docs
          .where((doc) => doc.data()['storeId'] == 'mall')
          .toList();

      expect(mallProducts.length, 1);
      expect(mallProducts.first.data()['name'], 'Mall Product');
    });

    test('upload multiple products simultaneously', () async {
      final futures = List.generate(5, (i) {
        return fakeFirestore.collection('products').add({
          'name': 'Product $i',
          'category': 'Cat $i',
          'price': (i + 1) * 10.0,
          'unit': '1 pc',
          'isActive': true,
          'storeId': 'mall',
        });
      });

      final refs = await Future.wait(futures);
      expect(refs.length, 5);

      final snapshot = await fakeFirestore.collection('products').get();
      expect(snapshot.docs.length, 5);
    });
  });

  // ─────────────────────────────────────────────
  // ORDER OPERATIONS
  // ─────────────────────────────────────────────

  group('Order creation and management', () {
    test('create order writes all required fields', () async {
      final ref = await fakeFirestore.collection('orders').add({
        'userId': 'user1',
        'customerName': 'John Doe',
        'items': [
          {'productId': 'p1', 'name': 'Milk', 'price': 60, 'quantity': 2, 'total': 120},
          {'productId': 'p2', 'name': 'Bread', 'price': 40, 'quantity': 1, 'total': 40},
        ],
        'subtotal': 160.0,
        'deliveryFee': 30.0,
        'tax': 0.0,
        'total': 190.0,
        'status': 'Pending',
        'deliveryStatus': 'Pending',
        'paymentStatus': 'Pending',
        'address': '123 Main St, City',
      });

      final doc = await fakeFirestore.collection('orders').doc(ref.id).get();
      final data = doc.data()!;

      expect(doc.exists, true);
      expect(data['userId'], 'user1');
      expect(data['customerName'], 'John Doe');
      expect((data['items'] as List).length, 2);
      expect(data['total'], 190.0);
      expect(data['status'], 'Pending');
      expect(data['deliveryStatus'], 'Pending');
      expect(data['paymentStatus'], 'Pending');
    });

    test('update order status (admin operation)', () async {
      final ref = await fakeFirestore.collection('orders').add({
        'userId': 'user1',
        'status': 'Pending',
        'deliveryStatus': 'Pending',
        'total': 100.0,
      });

      await fakeFirestore.collection('orders').doc(ref.id).update({
        'status': 'Accepted',
      });

      final doc = await fakeFirestore.collection('orders').doc(ref.id).get();
      expect(doc.data()!['status'], 'Accepted');
    });

    test('update delivery status with delivery partner', () async {
      final ref = await fakeFirestore.collection('orders').add({
        'userId': 'user1',
        'status': 'Accepted',
        'deliveryStatus': 'Pending',
        'total': 100.0,
      });

      await fakeFirestore.collection('orders').doc(ref.id).update({
        'deliveryStatus': 'Assigned',
        'deliveryPartner': 'Ravi',
      });

      final doc = await fakeFirestore.collection('orders').doc(ref.id).get();
      expect(doc.data()!['deliveryStatus'], 'Assigned');
      expect(doc.data()!['deliveryPartner'], 'Ravi');
    });

    test('fetch user orders filters by userId', () async {
      await fakeFirestore.collection('orders').add({
        'userId': 'user1',
        'total': 100.0,
        'status': 'Pending',
      });
      await fakeFirestore.collection('orders').add({
        'userId': 'user2',
        'total': 200.0,
        'status': 'Pending',
      });
      await fakeFirestore.collection('orders').add({
        'userId': 'user1',
        'total': 150.0,
        'status': 'Delivered',
      });

      final snapshot = await fakeFirestore
          .collection('orders')
          .where('userId', isEqualTo: 'user1')
          .get();

      expect(snapshot.docs.length, 2);
      for (final doc in snapshot.docs) {
        expect(doc.data()['userId'], 'user1');
      }
    });

    test('order status full lifecycle', () async {
      final ref = await fakeFirestore.collection('orders').add({
        'userId': 'user1',
        'status': 'Pending',
        'deliveryStatus': 'Pending',
        'paymentStatus': 'Pending',
        'total': 300.0,
      });

      final statuses = ['Accepted', 'Ready', 'On the way', 'Delivered'];
      for (final status in statuses) {
        await fakeFirestore.collection('orders').doc(ref.id).update({
          'status': status,
        });
      }

      final doc = await fakeFirestore.collection('orders').doc(ref.id).get();
      expect(doc.data()!['status'], 'Delivered');
    });
  });

  // ─────────────────────────────────────────────
  // TRANSACTIONAL ORDER + PAYMENT (simulated)
  // ─────────────────────────────────────────────

  group('Transactional order + payment creation', () {
    test('order and payment are created atomically in a transaction', () async {
      final orderRef = fakeFirestore.collection('orders').doc();
      final paymentRef = fakeFirestore.collection('payments').doc();

      await fakeFirestore.runTransaction((transaction) async {
        transaction.set(orderRef, {
          'userId': 'user1',
          'customerName': 'Alice',
          'items': [
            {'productId': 'p1', 'name': 'Cake', 'price': 500, 'quantity': 1, 'total': 500},
          ],
          'subtotal': 500.0,
          'deliveryFee': 30.0,
          'tax': 0.0,
          'total': 530.0,
          'status': 'Pending',
          'deliveryStatus': 'Pending',
          'paymentStatus': 'Pending',
          'paymentId': paymentRef.id,
          'address': '456 Elm St',
        });

        transaction.set(paymentRef, {
          'orderId': orderRef.id,
          'userId': 'user1',
          'amount': 530.0,
          'paymentMethod': 'UPI',
          'status': 'Pending',
          'transactionId': 'TXN-${orderRef.id}',
        });
      });

      // Verify both documents exist
      final orderDoc = await orderRef.get();
      final paymentDoc = await paymentRef.get();

      expect(orderDoc.exists, true);
      expect(paymentDoc.exists, true);

      // Verify cross-references
      expect(orderDoc.data()!['paymentId'], paymentRef.id);
      expect(paymentDoc.data()!['orderId'], orderRef.id);

      // Verify amounts match
      expect(orderDoc.data()!['total'], 530.0);
      expect(paymentDoc.data()!['amount'], 530.0);
    });

    test('transaction creates linked payment with correct method', () async {
      final orderRef = fakeFirestore.collection('orders').doc();
      final paymentRef = fakeFirestore.collection('payments').doc();

      await fakeFirestore.runTransaction((transaction) async {
        transaction.set(orderRef, {
          'userId': 'user2',
          'total': 200.0,
          'status': 'Pending',
          'paymentId': paymentRef.id,
        });
        transaction.set(paymentRef, {
          'orderId': orderRef.id,
          'userId': 'user2',
          'amount': 200.0,
          'paymentMethod': 'Credit Card',
          'cardLast4': '4242',
          'status': 'Pending',
          'transactionId': 'TXN-${orderRef.id}',
        });
      });

      final paymentDoc = await paymentRef.get();
      expect(paymentDoc.data()!['paymentMethod'], 'Credit Card');
      expect(paymentDoc.data()!['cardLast4'], '4242');
    });
  });

  // ─────────────────────────────────────────────
  // PAYMENT OPERATIONS
  // ─────────────────────────────────────────────

  group('Payment operations', () {
    test('create payment record', () async {
      final ref = await fakeFirestore.collection('payments').add({
        'orderId': 'ord1',
        'userId': 'user1',
        'amount': 190.0,
        'paymentMethod': 'UPI',
        'upiId': 'user@upi',
        'status': 'Completed',
        'transactionId': 'TXN-ord1',
      });

      final doc = await fakeFirestore.collection('payments').doc(ref.id).get();
      expect(doc.exists, true);
      expect(doc.data()!['amount'], 190.0);
      expect(doc.data()!['paymentMethod'], 'UPI');
      expect(doc.data()!['status'], 'Completed');
    });

    test('update payment status', () async {
      final ref = await fakeFirestore.collection('payments').add({
        'orderId': 'ord2',
        'userId': 'user1',
        'amount': 100.0,
        'status': 'Pending',
      });

      await fakeFirestore.collection('payments').doc(ref.id).update({
        'status': 'Completed',
      });

      final doc = await fakeFirestore.collection('payments').doc(ref.id).get();
      expect(doc.data()!['status'], 'Completed');
    });

    test('fetch user payments filters by userId', () async {
      await fakeFirestore.collection('payments').add({
        'userId': 'user1',
        'amount': 100.0,
        'status': 'Completed',
      });
      await fakeFirestore.collection('payments').add({
        'userId': 'user2',
        'amount': 200.0,
        'status': 'Completed',
      });

      final snapshot = await fakeFirestore
          .collection('payments')
          .where('userId', isEqualTo: 'user1')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['amount'], 100.0);
    });
  });

  // ─────────────────────────────────────────────
  // USER PROFILE OPERATIONS
  // ─────────────────────────────────────────────

  group('User profile operations', () {
    test('create user profile with merge', () async {
      await fakeFirestore.collection('users').doc('uid1').set({
        'firstName': 'Jane',
        'lastName': 'Doe',
        'email': 'jane@test.com',
        'phone': '+911234567890',
        'isActive': true,
        'isAdmin': false,
      });

      final doc = await fakeFirestore.collection('users').doc('uid1').get();
      expect(doc.exists, true);
      expect(doc.data()!['firstName'], 'Jane');
      expect(doc.data()!['isAdmin'], false);
    });

    test('admin flag is stored and retrievable', () async {
      await fakeFirestore.collection('users').doc('admin1').set({
        'firstName': 'Admin',
        'lastName': 'User',
        'phone': '+919999999999',
        'email': 'admin@mall.com',
        'isAdmin': true,
        'isActive': true,
      });

      final doc = await fakeFirestore.collection('users').doc('admin1').get();
      expect(doc.data()!['isAdmin'], true);
    });

    test('update user profile preserves unmodified fields', () async {
      await fakeFirestore.collection('users').doc('uid2').set({
        'firstName': 'Bob',
        'lastName': 'Smith',
        'email': 'bob@test.com',
        'phone': '+910000000000',
        'isAdmin': false,
      });

      await fakeFirestore.collection('users').doc('uid2').update({
        'email': 'bob.new@test.com',
      });

      final doc = await fakeFirestore.collection('users').doc('uid2').get();
      expect(doc.data()!['email'], 'bob.new@test.com');
      expect(doc.data()!['firstName'], 'Bob'); // unchanged
      expect(doc.data()!['isAdmin'], false); // unchanged
    });

    test('user addresses subcollection CRUD', () async {
      // Add address
      final addrRef = await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('addresses')
          .add({
        'label': 'Home',
        'address': '123 Main St, City',
        'latitude': 14.5853,
        'longitude': 121.0568,
        'isDefault': true,
      });

      // Read address
      final addrDoc = await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('addresses')
          .doc(addrRef.id)
          .get();
      expect(addrDoc.exists, true);
      expect(addrDoc.data()!['label'], 'Home');

      // Update address
      await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('addresses')
          .doc(addrRef.id)
          .update({'label': 'Work'});

      final updated = await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('addresses')
          .doc(addrRef.id)
          .get();
      expect(updated.data()!['label'], 'Work');

      // Delete address
      await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('addresses')
          .doc(addrRef.id)
          .delete();

      final deleted = await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('addresses')
          .doc(addrRef.id)
          .get();
      expect(deleted.exists, false);
    });
  });

  // ─────────────────────────────────────────────
  // CATEGORY OPERATIONS
  // ─────────────────────────────────────────────

  group('Category operations', () {
    test('add and fetch categories', () async {
      await fakeFirestore.collection('categories').add({
        'name': 'Dairy',
        'iconName': 'local_drink',
        'isActive': true,
      });
      await fakeFirestore.collection('categories').add({
        'name': 'Bakery',
        'iconName': 'bakery_dining',
        'isActive': true,
      });
      await fakeFirestore.collection('categories').add({
        'name': 'Archived',
        'iconName': 'category',
        'isActive': false,
      });

      final snapshot = await fakeFirestore.collection('categories').get();
      final active = snapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .toList();

      expect(active.length, 2);
    });
  });

  // ─────────────────────────────────────────────
  // SIMULTANEOUS READ/WRITE OPERATIONS
  // ─────────────────────────────────────────────

  group('Simultaneous Firestore operations', () {
    test('concurrent product writes all succeed', () async {
      final writes = <Future>[];
      for (int i = 0; i < 10; i++) {
        writes.add(fakeFirestore.collection('products').add({
          'name': 'Concurrent Product $i',
          'price': (i + 1) * 25.0,
          'isActive': true,
          'storeId': 'mall',
          'category': 'Test',
          'unit': '1 pc',
        }));
      }

      await Future.wait(writes);

      final snapshot = await fakeFirestore.collection('products').get();
      expect(snapshot.docs.length, 10);
    });

    test('concurrent reads and writes do not conflict', () async {
      // Seed data
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('products').add({
          'name': 'Seed Product $i',
          'price': 100.0,
          'isActive': true,
          'storeId': 'mall',
        });
      }

      // Simultaneous: read all products + write new products + read categories
      final results = await Future.wait([
        fakeFirestore.collection('products').get(),
        fakeFirestore.collection('products').add({
          'name': 'New During Read',
          'price': 999.0,
          'isActive': true,
          'storeId': 'mall',
        }),
        fakeFirestore.collection('categories').get(),
      ]);

      final productSnapshot = results[0] as dynamic;
      expect(productSnapshot.docs.length, greaterThanOrEqualTo(5));
    });

    test('concurrent order + payment + product fetch', () async {
      // Seed a product
      await fakeFirestore.collection('products').add({
        'name': 'Test Product',
        'price': 100.0,
        'isActive': true,
        'storeId': 'mall',
      });

      // Run order creation, payment creation, and product fetch simultaneously
      final results = await Future.wait([
        fakeFirestore.collection('orders').add({
          'userId': 'user1',
          'total': 130.0,
          'status': 'Pending',
          'items': [
            {'productId': 'p1', 'name': 'Test Product', 'quantity': 1, 'total': 100},
          ],
        }),
        fakeFirestore.collection('payments').add({
          'userId': 'user1',
          'amount': 130.0,
          'status': 'Pending',
          'paymentMethod': 'Cash',
        }),
        fakeFirestore.collection('products').get(),
      ]);

      // All three operations should succeed
      expect(results.length, 3);
      final productSnapshot = results[2] as dynamic;
      expect(productSnapshot.docs.length, 1);
    });

    test('order statistics aggregation', () async {
      // Seed multiple orders
      final orderData = [
        {'userId': 'u1', 'total': 100.0, 'status': 'Delivered'},
        {'userId': 'u2', 'total': 200.0, 'status': 'Delivered'},
        {'userId': 'u1', 'total': 150.0, 'status': 'Pending'},
        {'userId': 'u3', 'total': 300.0, 'status': 'Accepted'},
      ];

      for (final data in orderData) {
        await fakeFirestore.collection('orders').add(data);
      }

      final snapshot = await fakeFirestore.collection('orders').get();
      double totalRevenue = 0;
      int deliveredCount = 0;
      int pendingCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['total'] as num).toDouble();
        if (data['status'] == 'Delivered') deliveredCount++;
        if (data['status'] == 'Pending') pendingCount++;
      }

      expect(snapshot.docs.length, 4);
      expect(totalRevenue, 750.0);
      expect(deliveredCount, 2);
      expect(pendingCount, 1);
    });
  });

  // ─────────────────────────────────────────────
  // APP SETTINGS
  // ─────────────────────────────────────────────

  group('App settings (delivery zone)', () {
    test('read and write delivery zone settings', () async {
      await fakeFirestore.collection('app_settings').doc('delivery_zone').set({
        'name': 'SM Megamall',
        'latitude': 14.5853,
        'longitude': 121.0568,
        'radiusKm': 10.0,
      });

      final doc = await fakeFirestore
          .collection('app_settings')
          .doc('delivery_zone')
          .get();

      expect(doc.exists, true);
      expect(doc.data()!['name'], 'SM Megamall');
      expect(doc.data()!['radiusKm'], 10.0);
    });
  });
}
