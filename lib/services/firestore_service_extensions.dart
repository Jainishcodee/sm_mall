import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/order.dart';
import '../models/payment.dart';
import '../models/user_profile.dart';
import 'firestore_service.dart';

extension FirestoreServiceOrdersAndPayments on FirestoreService {
  // Reference getters
  CollectionReference<Map<String, dynamic>> get ordersCollection {
    return firestore.collection('orders');
  }

  CollectionReference<Map<String, dynamic>> get paymentsCollection {
    return firestore.collection('payments');
  }

  CollectionReference<Map<String, dynamic>> get usersCollection {
    return firestore.collection('users');
  }

  // ==================== ORDER OPERATIONS ====================

  /// Create a new order
  Future<String> createOrder({
    required String userId,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required double tax,
    required double total,
    required String status,
    String deliveryStatus = 'Pending',
    String? deliveryPartner,
    required String paymentStatus,
    required String address,
  }) async {
    final doc = await ordersCollection.add({
      'userId': userId,
      'customerName': customerName,
      'items': items,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'total': total,
      'status': status,
      'deliveryStatus': deliveryStatus,
      'deliveryPartner': deliveryPartner,
      'paymentStatus': paymentStatus,
      'address': address,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Atomically creates an order and its payment record in a single transaction.
  /// Returns the order document ID. If either write fails the whole operation
  /// is rolled back — no orphaned orders or payments.
  Future<String> placeOrderWithPayment({
    required String userId,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required double tax,
    required double total,
    required String address,
    required String paymentMethod,
    String? cardLast4,
    String? upiId,
    String? walletProvider,
    String? bankName,
  }) async {
    // Pre-generate document refs so both docs can reference each other.
    final orderRef = ordersCollection.doc();
    final paymentRef = paymentsCollection.doc();

    await firestore.runTransaction((transaction) async {
      // ── Create order ──
      transaction.set(orderRef, {
        'userId': userId,
        'customerName': customerName,
        'items': items,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'tax': tax,
        'total': total,
        'status': 'Pending',
        'deliveryStatus': 'Pending',
        'paymentStatus': 'Pending',
        'paymentId': paymentRef.id,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── Create payment ──
      transaction.set(paymentRef, {
        'orderId': orderRef.id,
        'userId': userId,
        'amount': total,
        'paymentMethod': paymentMethod,
        'cardLast4': cardLast4,
        'upiId': upiId,
        'walletProvider': walletProvider,
        'bankName': bankName,
        'status': 'Pending',
        'transactionId': 'TXN-${orderRef.id}',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return orderRef.id;
  }

  /// Get a specific order
  Future<Order?> getOrder(String orderId) async {
    final doc = await ordersCollection.doc(orderId).get();
    if (!doc.exists) return null;
    return Order.fromFirestore(doc.id, doc.data() ?? {});
  }

  /// Get user's orders
  Future<List<Order>> getUserOrders(String userId) async {
    final snapshot = await ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Order.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Stream user's orders in real-time
  Stream<List<Order>> streamUserOrders(String userId) {
    return ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Order.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  /// Stream all orders (admin only)
  Stream<List<Order>> streamAllOrders() {
    return ordersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Order.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  /// Update order status (admin only)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final updateData = <String, dynamic>{
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Keep delivery timeline in sync for final state.
    if (newStatus == 'Delivered') {
      updateData['deliveryStatus'] = 'Delivered';
    }

    await ordersCollection.doc(orderId).update(updateData);
  }

  /// Update delivery status (admin only)
  Future<void> updateOrderDeliveryStatus(
    String orderId,
    String deliveryStatus, {
    String? deliveryPartner,
  }) async {
    await ordersCollection.doc(orderId).update({
      'deliveryStatus': deliveryStatus,
      if (deliveryPartner != null) 'deliveryPartner': deliveryPartner,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update order payment status
  Future<void> updateOrderPaymentStatus(
    String orderId,
    String paymentStatus,
  ) async {
    await ordersCollection.doc(orderId).update({
      'paymentStatus': paymentStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get order statistics (admin)
  Future<Map<String, dynamic>> getOrderStats() async {
    final allOrders = await ordersCollection.get();

    double totalRevenue = 0;
    int totalOrders = allOrders.docs.length;
    int deliveredOrders = 0;
    int pendingOrders = 0;

    for (final doc in allOrders.docs) {
      final data = doc.data();
      totalRevenue += (data['total'] ?? 0).toDouble();

      final status = data['status'] ?? '';
      if (status == 'Delivered') {
        deliveredOrders++;
      } else if (status == 'Pending') {
        pendingOrders++;
      }
    }

    return {
      'totalOrders': totalOrders,
      'deliveredOrders': deliveredOrders,
      'pendingOrders': pendingOrders,
      'totalRevenue': totalRevenue,
      'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
    };
  }

  // ==================== PAYMENT OPERATIONS ====================

  /// Create a new payment record
  Future<String> createPayment({
    required String orderId,
    required String userId,
    required double amount,
    required String paymentMethod,
    required String transactionId,
    String? cardLast4,
    String? upiId,
    String? walletProvider,
    String? bankName,
  }) async {
    final doc = await paymentsCollection.add({
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'cardLast4': cardLast4,
      'upiId': upiId,
      'walletProvider': walletProvider,
      'bankName': bankName,
      'status': 'Completed',
      'transactionId': transactionId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Get a specific payment
  Future<Payment?> getPayment(String paymentId) async {
    final doc = await paymentsCollection.doc(paymentId).get();
    if (!doc.exists) return null;
    return Payment.fromFirestore(doc.id, doc.data() ?? {});
  }

  /// Get user's payments
  Future<List<Payment>> getUserPayments(String userId) async {
    final snapshot = await paymentsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Payment.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Stream user's payments in real-time
  Stream<List<Payment>> streamUserPayments(String userId) {
    return paymentsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Payment.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  /// Update payment status
  Future<void> updatePaymentStatus(String paymentId, String newStatus) async {
    await paymentsCollection.doc(paymentId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== USER PROFILE OPERATIONS ====================

  /// Create user profile
  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    await usersCollection.doc(userId).set({
      'name': name,
      'email': email,
      'phone': phone,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await usersCollection.doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc.id, doc.data() ?? {});
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (phone != null) updates['phone'] = phone;

    await usersCollection.doc(userId).update(updates);
  }

  /// Add/Update address for user
  Future<String> addOrUpdateAddress({
    required String userId,
    required String label,
    required String address,
    required double latitude,
    required double longitude,
    required bool isDefault,
    String? addressId,
  }) async {
    final ref = usersCollection.doc(userId).collection('addresses');

    if (addressId != null) {
      // Update existing address
      await ref.doc(addressId).update({
        'label': label,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return addressId;
    } else {
      // Create new address
      final doc = await ref.add({
        'label': label,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    }
  }

  /// Get user's addresses
  Future<List<Map<String, dynamic>>> getUserAddresses(String userId) async {
    final snapshot = await usersCollection
        .doc(userId)
        .collection('addresses')
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Stream user's addresses
  Stream<List<Map<String, dynamic>>> streamUserAddresses(String userId) {
    return usersCollection.doc(userId).collection('addresses').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  /// Delete address
  Future<void> deleteAddress(String userId, String addressId) async {
    await usersCollection
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }
}
